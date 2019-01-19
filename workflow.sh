#! /usr/bin/env bash


# Abort if any part fails
set -e
cd `dirname $0`

chmod +x ./R/1_getData.R
chmod +x ./R/2_subsettingData.R
chmod +x ./R/3_DEA.R
chmod +x ./R/4_enrichmentAnalysis.R
chmod +x ./R/5_keggpathway.R

# Defaults
pval=0.0001
lfc=4
ea=false
skipgettingdata=false

usage()
{
    cat <<EOF
Usage: $0 [-s] [-p pvalue=$pval] [-l logfoldchange=$lfc] [-d deafilenames=DATETIME-USER-dea-CANCERTYPE1-vs-CANCERTYPE2] [-E] [-e enrichfilenames=DATETIME-USER-ea-CANCERTYPE1-vs-CANCERTYPE2] [-k pathwayids] CANCERTYPE1 CANCERTYPE2

    The default values are showed after the equals characters in usage string.

    -h                  Show this help message.
    -p                  p-value threshold.
    -l                  Log fold change threshold.
    -d                  Output filename for the DEA resulting files. '.pdf' and
                        '.csv' extensions will be appended.
    -E                  Perform enrichment analysis with default output 
                        filename for the resulting files.
    -e                  Perform enrichment analysis setting the output filename
                        to resulting files. '.pdf' and '.csv' extensions will be 
                        appended.
    -k                  Fetch the pathway visualization from KEGG database.
                        Provide the KEGG pathways in a comma separated string 
                        like "-k hsa05165,hsa04915". An enrichment analysis 
                        must be performed before this step. If no configuration
                        is provided for previous steps they will be executed
                        with default values. PNG images and XML data will be
                        placed in '`dirname $0`' path.
    -s                  Skip the getting data step, using cached data.
    CANCERTYPE          (TNBC|Basal|LumA)
EOF
}

printinfo()
{
    echo -e "\e[36m\e[1m$1\e[0m"
}

printerror()
{
    echo -e "\e[31m\e[1m$1\e[0m"
}

# Parse options
while getopts ":p:l:g:c:hEe:k:s" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        s)
            skipgettingdata=true
            ;;
        p)
            pval=$OPTARG
            ;;
        l)
            lfc=$OPTARG
            ;;
        d)
            deafilenames=$OPTARG
            ;;
        E)
            ea=true
            ;;
        e)
            ea=true
            eafilenames=$OPTARG
            ;;
        k)
            ea=true
            pwids=$OPTARG
            ;;
        \?)
            printerror "Invalid option: -$OPTARG."
            exit 1
            ;;
        :)
            printerror "Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done
shift $(($OPTIND - 1))


# Check that the call is coherent
if [[ $# -ne 2 ]]; then
    printerror "You must provide the two cancer types for the DEA: TNBC|Basal|LumA."
    exit 1
fi

if [ $skipgettingdata = false ]; then
    printinfo "Getting data"
    ./R/1_getData.R
    ./R/2_subsettingData.R
fi

cancertype1=$1
cancertype2=$2

if [ "$deafilenames" = "" ]; then
    deafilenames="`date +%Y%m%d-%H%M%S`-$USER-dea-$cancertype1-vs-$cancertype2"
fi

printinfo "Performing differential expression analysis: $cancertype1 vs $cancertype2."
./R/3_DEA.R $cancertype1 $cancertype2 $pval $lfc $deafilenames

if [ $ea = true ]; then
    if [ "$eafilenames" = "" ]; then
        eafilenames="`date +%Y%m%d-%H%M%S`-$USER-ea-$cancertype1-vs-$cancertype2"
    fi
    printinfo "Performing the enrichment analysis."
    ./R/4_enrichmentAnalysis.R $pval $lfc $eafilenames
    if [ "$pwids" != "" ]; then
        printinfo "Fetching pathway visualization images from KEGG."
        ./R/5_keggpathway.R $pwids
    fi
fi
