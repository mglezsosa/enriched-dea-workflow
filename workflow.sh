#! /usr/bin/env bash

cd `dirname $0`

chmod +x ./R/1_getData.R
chmod +x ./R/2_subsettingData.R
chmod +x ./R/3_DEA.R

# Defaults
pval=0.01
lfc=2
all=false

usage()
{
    cat <<EOF
Usage: $0 [-a] [-p pvalue=$pval] [-l logfoldchange=$lfc] [-g pdfoutputfile=DATETIME-USER-CANCERTYPE1-vs-CANCERTYPE2.pdf] [-c csvoutputfile=DATETIME-USER-CANCERTYPE1-vs-CANCERTYPE2.csv] [CANCERTYPE1 CANCERTYPE2]

    The default values are showed after the equals charachters in usage string.

    -h                  Show this help message.
    -a                  Perform both combinations of DEA. You may set pvalue and log fold change
                        but no output file names neither cancer types as arguments.
    -p                  p-value threshold.
    -l                  Log fold change threshold.
    -g                  PDF file output path.
    -c                  CSV file output path.
    CANCERTYPE          (TNBC|Basal|LumA)
EOF
}

updateoutfilename()
{
    outfilename="`date +%Y%m%d-%H%M%S`-$USER-$cancertype1-vs-$cancertype2"
}

# Parse options
while getopts ":p:l:g:c:ah" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        a)
            all=true
            ;;
        p)
            pval=$OPTARG
            ;;
        l)
            lfc=$OPTARG
            ;;
        g)
            if [[ $all = true ]]; then
                echo "Not used arguments: do not provide cancer types neither output file names if 'all' option (-a) is setted." >&2
                exit 1
            fi
            pdfoutputfile=$OPTARG
            ;;
        c)
            if [[ $all = true ]]; then
                echo "Not used arguments: do not provide cancer types neither output file names if 'all' option (-a) is setted." >&2
                exit 1
            fi
            csvoutputfile=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
shift $(($OPTIND - 1))

# Check that the call is coherent
if [[ $all = false && $# -ne 2 ]]; then
    echo "You must provide the two cancer types for the DEA: TNBC|Basal|LumA."
    exit 1
fi
if [[ $all = true && $# -ne 0 ]]; then
    echo "Not used arguments: do not provide cancer types neither output file names if 'all' option (-a) is setted." >&2
    exit 1
fi

# Perform the 4 combinations of DEA if all is setted
if [ $all = true ]; then
    cancertype1="LumA"
    cancertype2="TNBC"
    updateoutfilename
    ./workflow.sh -p $pval -l $lfc -g $outfilename.pdf -c $outfilename.csv $cancertype1 $cancertype2
    cancertype1="LumA"
    cancertype2="Basal"
    updateoutfilename
    ./workflow.sh -p $pval -l $lfc -g $outfilename.pdf -c $outfilename.csv $cancertype1 $cancertype2
    cancertype1="TNBC"
    cancertype2="LumA"
    updateoutfilename
    ./workflow.sh -p $pval -l $lfc -g $outfilename.pdf -c $outfilename.csv $cancertype1 $cancertype2
    cancertype1="Basal"
    cancertype2="LumA"
    updateoutfilename
    ./workflow.sh -p $pval -l $lfc -g $outfilename.pdf -c $outfilename.csv $cancertype1 $cancertype2
else
    ./R/1_getData.R
    ./R/2_subsettingData.R
    cancertype1=$1
    cancertype2=$2
    # Set default filename if not provided by the user
    updateoutfilename
    if [ "$pdfoutputfile" = "" ]; then
        pdfoutputfile=$outfilename.pdf
    fi
    if [ "$csvoutputfile" = "" ]; then
        csvoutputfile=$outfilename.csv
    fi
    ./R/3_DEA.R $cancertype1 $cancertype2 $pval $lfc $pdfoutputfile $csvoutputfile
fi

# rm ./R/*.RData