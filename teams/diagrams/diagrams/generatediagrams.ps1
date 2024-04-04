


$path = "./output"
if(Test-Path -Path $path){
    Write-Host "Output Spanish folder already exists.Removing..."
    Remove-Item $path -Recurse
}
New-Item -Path $path -ItemType Directory 
Write-Host "Output Spanish folder created successfully."


    
<#FORMATS OUTPUT:
Param name	        Short param name	Output format	Comment
-tpng	            -png	            PNG	            Default
-tsvg	            -svg	            SVG	            Further details can be found here
-teps	            -eps	            EPS	            Further details can be found here
-teps:text	        -eps:text	        EPS	            This option keeps text as text
-tpdf	            -pdf	            PDF	            Further details can be found here
-tvdx	            -vdx	            VDX	            Microsoft Visio Document
-txmi	            -xmi	            XMI	            Further details can be found here
-tscxml	            -scxml	            SCXML	
-thtml	            -html	            HTML	        Alpha feature: do not use
-ttxt	            -txt	            ATXT	        ASCII art. Further details can be found here
-tutxt	            -utxt	            UTXT	        ASCII art using Unicode characters
-tlatex	            -latex	            LATEX	        Further details can be found here
-tlatex:nopreamble	-latex:nopreamble	LATEX	        Contains no LaTeX preamble creating a document
-tbraille	        -braille	        PNG	            Braille image [Ref. QA-4752]
#>
java -jar ./plantuml-1.2023.9.jar -tsvg "./input/*uml" -o "../output/"