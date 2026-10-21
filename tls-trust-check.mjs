// Prüft, ob dieser Node-Prozess die kompromittierten eMudhra/emSign-Zwischenzertifikate
// (Oktober 2026, https://emudhra.we-have-a-problem.com/) ablehnt.
//
// Bis einschließlich Node 26.12.0 vertraut der mitgelieferte Root-Store noch dem Cross-Signer
// „emSign ECC Root CA - G3“ und damit den acht betroffenen Intermediates; der Node-Fix
// (nodejs/node#66871) ist noch in keinem Release. Deshalb laufen alle Prozesse in den
// node-base-Images mit --use-openssl-ca gegen den gepatchten Debian-CA-Store. Die Images führen
// dieses Skript beim Bau der Basis und als ersten ONBUILD-Schritt jedes abgeleiteten Images aus;
// es liegt im Image unter /usr/local/lib/trigo/tls-trust-check.mjs.
//
// Aufruf:
//   node tls-trust-check.mjs           Offline-Prüfung von Flags, Umgebungsvariablen und CA-Stores
//   node tls-trust-check.mjs --probe   zusätzlich echte HTTPS-Verbindungen zu den Testhosts des
//                                      Advisories (müssen mit Zertifikatsfehler scheitern) und
//                                      zu einer Kontroll-URL (muss gelingen)
import { X509Certificate, createHash } from 'node:crypto';
import { request } from 'node:https';
import { resolve } from 'node:path';
import { getCACertificates } from 'node:tls';
import { pathToFileURL } from 'node:url';

// SPKI-SHA-256 der vier Roots und acht Intermediates aus roots.json und
// impacted-intermediates.json des Advisories. Der Schlüssel-Hash deckt auch neu ausgestellte
// Zertifikate für denselben Schlüssel ab.
export const compromisedKeys = new Map([
    ['c619e4780ed8e0abeda24ad732567de4383a7ea941338f6d1a7d1b49ac792fe9', 'emSign Root TLS CA - G3'],
    ['0a6c2b2ca5b364207954171987ac9d2178561569d8205457e77ca90c32ede282', 'emSign Root CS CA - G3'],
    ['bd153ed7b0434f6886b17bce8bbe84ed340c7132d702a8f4fa318f756ecbd6f3', 'AAA Certificate Services'],
    ['8d417db2dd8bf5e3084d1e3f196d583849d81bdd4c00c70b9d39369e96b8c782', 'emSign ECC Root CA - G3'],
    ['ebed6475c2c2d80fcb199f3fe8dd6e6b3ce60b77eb15d4e42c3dec0c6f5b5105', 'EM DV TLS CA - G3B'],
    ['43bffa19d6ef651451f6841e019931e96f6f2eaeff28ab4b6f1ce4576de2717b', 'EM OV TLS CA - G3B'],
    ['e0254c7fcdc265e2f0f8a428dabb75ab4ae039b4872d62f5ee57f0877d5a8a41', 'EM EV TLS CA - G3B'],
    ['49dd353dc2b919a3770645117d0e60c16115e7d1bc259eefe734b00ea434fe5f', 'EM DV TLS CA - G3C'],
    ['63ecefee431d49523bc1136c4e72d0206a477086caf606cd5cf025686c109cf8', 'EM OV TLS CA - G3C'],
    ['5c0660a2b164910d8ff589c18e14552e9e0ec237dcefe2cb736d41a4811f81a0', 'EM EV TLS CA - G3C'],
    ['ec4ffa1ad0ac88081314b7aaffef6a91f97cd57291bb5ba686c5415f5eb4f6b6', 'EM OV CS CA - G3B'],
    ['92c063d67e8f14db71d288e11266ffdaf69cbf115f7bab14f3bc2f68d25e0e30', 'EM OV CS CA - G3C'],
]);

// Testhosts des Advisories: je ein Leaf unter jedem betroffenen TLS-Intermediate, einmal über
// „emSign Root TLS CA - G3“ (cross-signiert von „emSign ECC Root CA - G3“) und einmal über den
// AAA-Cross-Sign.
export const advisoryHosts = ['dv', 'ov', 'ev'].flatMap((kind) =>
    ['g3b', 'g3c'].flatMap((generation) => [
        `${kind}-${generation}-emudhra.we-have-a-problem.com`,
        `${kind}-${generation}-aaa-emudhra.we-have-a-problem.com`,
    ]),
);

// Kontrolle: die npm-Registry, von der beide Builds ihre Abhängigkeiten laden.
export const controlUrl = 'https://registry.npmjs.org/';
const probeTimeoutMs = 15_000;

// Nur Fehler beim Kettenaufbau belegen Misstrauen. DNS-Fehler, Timeouts oder HTTP-Antworten
// beweisen nichts.
const trustRejectionCodes = new Set([
    'CERT_REVOKED',
    'CERT_UNTRUSTED',
    'SELF_SIGNED_CERT_IN_CHAIN',
    'UNABLE_TO_GET_ISSUER_CERT',
    'UNABLE_TO_GET_ISSUER_CERT_LOCALLY',
    'UNABLE_TO_VERIFY_LEAF_SIGNATURE',
]);

function nodeFlags({ execArgv, nodeOptions }) {
    return [...execArgv, ...(nodeOptions ?? '').split(/\s+/u).filter(Boolean)];
}

function keyHash(pem) {
    const spki = new X509Certificate(pem).publicKey.export({ type: 'spki', format: 'der' });
    return createHash('sha256').update(spki).digest('hex');
}

/**
 * Liefert die Gründe, warum dieser Prozess einer kompromittierten Kette noch vertrauen könnte.
 * Leer, wenn die Konfiguration sicher ist.
 */
export function inspectTlsTrust({
    execArgv,
    nodeOptions,
    rejectUnauthorized,
    sslCertDir,
    systemCertificates,
    extraCertificates,
}) {
    const issues = [];
    if (rejectUnauthorized === '0') {
        issues.push('NODE_TLS_REJECT_UNAUTHORIZED=0 schaltet die Zertifikatsprüfung ab');
    }
    // OpenSSL liest jedes Verzeichnis einer durch Doppelpunkt getrennten Liste, Node zählt den
    // gesamten Wert aber als ein Verzeichnis auf. Die Store-Prüfung unten würde die übrigen
    // Verzeichnisse übersehen.
    if (sslCertDir?.includes(':')) {
        issues.push('SSL_CERT_DIR enthält mehrere Verzeichnisse, die diese Prüfung nicht vollständig untersuchen kann');
    }
    const flags = nodeFlags({ execArgv, nodeOptions });
    if (!flags.includes('--use-openssl-ca')) {
        issues.push('Node muss mit --use-openssl-ca laufen; die mitgelieferten Roots vertrauen den kompromittierten CAs');
    }
    for (const flag of ['--use-bundled-ca', '--use-system-ca']) {
        if (flags.includes(flag)) issues.push(`${flag} fügt die mitgelieferten Roots von Node wieder hinzu`);
    }
    if (systemCertificates.length === 0) {
        issues.push('Der OpenSSL-CA-Store ist leer; gepatchtes Paket ca-certificates installieren');
    }
    for (const [source, certificates] of [
        ['OpenSSL-CA-Store', systemCertificates],
        ['NODE_EXTRA_CA_CERTS', extraCertificates],
    ]) {
        const trusted = new Set(certificates.map(keyHash).filter((hash) => compromisedKeys.has(hash)));
        for (const hash of trusted) issues.push(`${source} vertraut ${compromisedKeys.get(hash)}`);
    }
    return issues;
}

/** Bewertet einen HTTPS-Versuch gegen einen Host, der abgelehnt werden muss. */
export function classifyAdvisoryAttempt(attempt) {
    if (attempt.status !== undefined) return 'accepted';
    return trustRejectionCodes.has(attempt.code) ? 'rejected' : 'inconclusive';
}

async function fetchAttempt(url) {
    try {
        const response = await fetch(url, { signal: AbortSignal.timeout(probeTimeoutMs) });
        await response.body?.cancel();
        return { client: 'fetch', status: response.status };
    } catch (error) {
        const cause = error instanceof Error && error.cause instanceof Error ? error.cause : error;
        return { client: 'fetch', code: cause?.code ?? cause?.name };
    }
}

function httpsAttempt(url) {
    return new Promise((resolveAttempt) => {
        const outgoing = request(url, { timeout: probeTimeoutMs }, (response) => {
            response.resume();
            resolveAttempt({ client: 'node:https', status: response.statusCode });
        });
        outgoing.on('timeout', () =>
            outgoing.destroy(Object.assign(new Error('timeout'), { code: 'ETIMEDOUT' })),
        );
        outgoing.on('error', (error) => resolveAttempt({ client: 'node:https', code: error.code }));
        outgoing.end();
    });
}

async function probe() {
    const attempts = await Promise.all(
        advisoryHosts.flatMap((host) => {
            const url = `https://${host}/`;
            return [fetchAttempt(url), httpsAttempt(url)].map(async (attempt) => ({
                url,
                ...(await attempt),
            }));
        }),
    );
    const control = await Promise.all([fetchAttempt(controlUrl), httpsAttempt(controlUrl)]);
    let failed = false;
    for (const attempt of attempts) {
        const outcome = classifyAdvisoryAttempt(attempt);
        failed ||= outcome !== 'rejected';
        process.stdout.write(`${outcome} ${attempt.client} ${attempt.url} ${attempt.status ?? attempt.code}\n`);
    }
    for (const attempt of control) {
        const succeeded = attempt.status !== undefined && attempt.status < 400;
        failed ||= !succeeded;
        process.stdout.write(
            `${succeeded ? 'control-ok' : 'control-failed'} ${attempt.client} ${controlUrl} ${attempt.status ?? attempt.code}\n`,
        );
    }
    return !failed;
}

async function main() {
    const issues = inspectTlsTrust({
        execArgv: process.execArgv,
        nodeOptions: process.env.NODE_OPTIONS,
        rejectUnauthorized: process.env.NODE_TLS_REJECT_UNAUTHORIZED,
        sslCertDir: process.env.SSL_CERT_DIR,
        systemCertificates: getCACertificates('system'),
        extraCertificates: getCACertificates('extra'),
    });
    if (issues.length > 0) {
        throw new Error(`TLS-Vertrauensprüfung fehlgeschlagen:\n- ${issues.join('\n- ')}`);
    }
    process.stdout.write(`TLS-Vertrauensprüfung bestanden auf Node ${process.versions.node}\n`);
    if (process.argv.includes('--probe') && !(await probe())) {
        throw new Error('TLS-Probe fehlgeschlagen: eine kompromittierte Kette wurde nicht abgelehnt oder die Kontrolle scheiterte');
    }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
    main().catch((error) => {
        process.stderr.write(`${error instanceof Error ? error.message : 'TLS-Vertrauensprüfung fehlgeschlagen'}\n`);
        process.exitCode = 1;
    });
}
