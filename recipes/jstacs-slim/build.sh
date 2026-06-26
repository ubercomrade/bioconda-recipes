#!/usr/bin/env bash
set -euo pipefail

SHARE_DIR="${PREFIX}/share/${PKG_NAME}-${PKG_VERSION}-${PKG_BUILDNUM}"
mkdir -p "${SHARE_DIR}" "${PREFIX}/bin" build/classes build/cli

# Keep this classpath close to upstream build.xml.
# Do NOT use `find lib -name '*.jar'`, because lib/xml-commons/batik.jar
# can break javac/java with URI parsing errors in conda-build paths.
CP="lib/BigWig.jar"
CP="${CP}:lib/junit-4.13-beta-3.jar"
CP="${CP}:lib/htsjdk-2.5.0-4-gd683012-SNAPSHOT.jar"
CP="${CP}:lib/numericalMethods.jar"
CP="${CP}:lib/RClient-0.6.7.jar"
CP="${CP}:lib/biojava-live.jar"
CP="${CP}:lib/bytecode-1.9.0.jar"
CP="${CP}:lib/core-1.9.0.jar"
CP="${CP}:lib/xml-commons/pdf-transcoder.jar"
CP="${CP}:lib/xml-commons/xmlgraphics-commons-1.5.jar"
CP="${CP}:lib/Jama-1.0.3.jar"
CP="${CP}:lib/xml-commons/batik-transcoder.jar"
CP="${CP}:lib/xml-commons/batik-dom.jar"
CP="${CP}:lib/xml-commons/batik-svggen.jar"
CP="${CP}:lib/xml-commons/batik-svg-dom.jar"
CP="${CP}:lib/xml-commons/batik-awt-util.jar"
CP="${CP}:lib/xml-commons/batik-util.jar"
CP="${CP}:lib/ssj/colt-1.2.0.jar"
CP="${CP}:lib/ssj/ssj-3.3.1.jar"

if compgen -G "lib/graaljs/*.jar" > /dev/null; then
    CP="${CP}:$(find lib/graaljs -name '*.jar' -print | paste -sd: -)"
fi

cat > build/cli/JstacsSlimCLI.java <<'EOF'
import de.jstacs.tools.JstacsTool;
import de.jstacs.tools.ui.cli.CLI;

import projects.slim.SlimDimontTool;

public class JstacsSlimCLI {
    public static void main(String[] args) throws Exception {
        JstacsTool[] tools = new JstacsTool[] {
            new SlimDimontTool()
        };
        CLI cli = new CLI(tools);
        cli.run(args);
    }
}
EOF

javac \
    -encoding UTF-8 \
    -source 8 \
    -target 8 \
    -cp "${CP}" \
    -sourcepath ".:build/cli" \
    -d build/classes \
    build/cli/JstacsSlimCLI.java

jar cf "${SHARE_DIR}/jstacs-slim.jar" -C build/classes .

cp -R lib "${SHARE_DIR}/lib"

# This umbrella jar is not part of upstream's explicit build.xml classpath and
# can trigger URI parsing errors. Keep the explicit Batik component jars instead.
rm -f "${SHARE_DIR}/lib/xml-commons/batik.jar"

cat > "${SHARE_DIR}/classpath.sh" <<'EOF'
LIB_DIR="${SHARE_DIR}/lib"

CP="${SHARE_DIR}/jstacs-slim.jar"
CP="${CP}:${LIB_DIR}/BigWig.jar"
CP="${CP}:${LIB_DIR}/junit-4.13-beta-3.jar"
CP="${CP}:${LIB_DIR}/htsjdk-2.5.0-4-gd683012-SNAPSHOT.jar"
CP="${CP}:${LIB_DIR}/numericalMethods.jar"
CP="${CP}:${LIB_DIR}/RClient-0.6.7.jar"
CP="${CP}:${LIB_DIR}/biojava-live.jar"
CP="${CP}:${LIB_DIR}/bytecode-1.9.0.jar"
CP="${CP}:${LIB_DIR}/core-1.9.0.jar"
CP="${CP}:${LIB_DIR}/xml-commons/pdf-transcoder.jar"
CP="${CP}:${LIB_DIR}/xml-commons/xmlgraphics-commons-1.5.jar"
CP="${CP}:${LIB_DIR}/Jama-1.0.3.jar"
CP="${CP}:${LIB_DIR}/xml-commons/batik-transcoder.jar"
CP="${CP}:${LIB_DIR}/xml-commons/batik-dom.jar"
CP="${CP}:${LIB_DIR}/xml-commons/batik-svggen.jar"
CP="${CP}:${LIB_DIR}/xml-commons/batik-svg-dom.jar"
CP="${CP}:${LIB_DIR}/xml-commons/batik-awt-util.jar"
CP="${CP}:${LIB_DIR}/xml-commons/batik-util.jar"
CP="${CP}:${LIB_DIR}/ssj/colt-1.2.0.jar"
CP="${CP}:${LIB_DIR}/ssj/ssj-3.3.1.jar"

if compgen -G "${LIB_DIR}/graaljs/*.jar" > /dev/null; then
    CP="${CP}:$(find "${LIB_DIR}/graaljs" -name '*.jar' -print | paste -sd: -)"
fi

export CP
EOF

cat > "${PREFIX}/bin/jstacs-slim" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SHARE_BASE="$(dirname "$(dirname "$0")")/share"
SHARE_DIR="$(find "${SHARE_BASE}" -maxdepth 1 -type d -name 'jstacs-slim-*' | sort | tail -n 1)"

# shellcheck source=/dev/null
source "${SHARE_DIR}/classpath.sh"

exec java ${JAVA_OPTS:-} -cp "${CP}" JstacsSlimCLI "$@"
EOF

chmod +x "${PREFIX}/bin/jstacs-slim"
