import os
import lxml.html

root = lxml.html.fromstring(open('index.html', 'rb').read())

for num, expr in enumerate(root.xpath('//math')):
    mml = lxml.html.tostring(expr)
    mml = mml.replace('<math display="block">', '<math xmlns="https://www.w3.org/1998/Math/MathML/">')
    with open('{}.mml'.format(num), 'wb') as fp:
        fp.write('<article xmlns="http://docbook.org/ns/docbook" version="5.0"><title>Area enclosed by a circle</title> <equation>\n')
        fp.write(mml)
        fp.write('</equation></article>\n')

    cmd = 'java -jar saxon9he.jar -s:{}.mml -xsl:xsl/invoke-mml2tex.xsl  --suppressXsltNamespaceCheck:on'.format(num)
    print num+1, cmd
    os.system(cmd)
