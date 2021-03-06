#The asmOrganelle.sh pipeline has been tested with the following software versions
#minimap2 2.10-r764-dirty
#miniasm 0.2-r168-dirty
#racon v1.2.1
#mirabait 4.9.6
#pigz 2.3.4
#EMBOSS 6.6.0.0
#ncbi_blast+ 2.7.1+

minimap2 --version
if [ $? -ne 0 ]; then
 echo minimap2 was not found
 exit 1
fi

miniasm  -V
if [ $? -ne 0 ]; then
 echo miniasm was not found
 exit 1
fi

racon --version
if [ $? -ne 0 ]; then
 echo racon was not found
 exit 1
fi

mirabait -v
if [ $? -ne 0 ]; then
 echo mirabait was not found
 exit 1
fi

pigz --version
if [ $? -ne 0 ]; then
 echo pigz was not found
 exit 1
fi

embossversion 
if [ $? -ne 0 ]; then
 echo EMBOSS was not found
 exit 1
fi

blastn -version
if [ $? -ne 0 ]; then
 echo NCBI BLAST+ was not found
 exit 1
fi
