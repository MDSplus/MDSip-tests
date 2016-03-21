#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="2026392833"
MD5="a9ec28a9f2b8d6c37159cefffc279ec1"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3972"
keep="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
    while true
    do
      MS_Printf "Please type y to accept, n otherwise: "
      read yn
      if test x"$yn" = xn; then
        keep=n
	eval $finish; exit 1
        break;
      elif test x"$yn" = xy; then
        break;
      fi
    done
  fi
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.2.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || type digest`
    PATH="$OLD_PATH"

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 507 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 24 KB
	echo Compression: gzip
	echo Date of packaging: Mon Mar 21 15:49:38 CET 2016
	echo Built with Makeself version 2.2.0 on linux-gnu
	echo Build command was: "/bin/sh \\
    \"--header\" \\
    \"/home/andrea/devel/rfx/tests/build/../MDSip-tests/reports/setup_server/makeself-header.sh\" \\
    \".setup_server.tmp\" \\
    \"setup_server.sh\" \\
    \"setup server script\" \\
    \"./setup.sh\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\".setup_server.tmp\"
	echo KEEP=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=24
	echo OLDSKIP=508
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 507 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 507 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 507 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 24 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 24; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (24 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
‹ 
ğVíksGÒ_Ù_ÑYqÈ	$ÙW’Ñ…HX¡‚%Pœœ¬¢–İA¬µìîíCÈü÷ë™}
ìØSÅÔÅbgº{zú5İ3sÕg_½mb{½³Ck¯w6Ó£ö¬Võz{ssgs³şl³¶¹à°óì´Ğ4à™fÓÃ=6şmÕŸ¡[õ'—şëÛµúëœşëµWõg°¹ÒÿWok?lŒL{ÃŸ(Ê°[3 Çæyç+hPaŠÒ?8m÷İæq«Q,4ŸÙÚ”ZÜTËrlxØ>Å1ÃôRC
»u/€Aóô¨5şrÒ4Š÷©¯İ†åèš5qü`–îœ¦€ék·ño4–<\¿wrÒI ùçnc#˜ºSÃ7İaÀˆ¸r|ØïuÎú‚ÏûÔ‡¾·Á!×
ı·{YÀ—'ªt‡öÏ§ÍÓ?†½æà—< ev‹÷9 ˜s‹¦¢¶›“£†aj–s©(Šë™v0œ0Ë-•á^Ñµ Ş¼ÖÉ[åÌ×.Ù.å@¥ç˜í_À¹îL§h´Š¢É¡è³"Zü9ùX©ĞDeˆÚ%ê?˜˜>P·èŠ¡]„¦å$Ğd->ó®™|#¡Ï(l¬…VÀUXiøHÃwÇ*ghP )?p<†İv †h	¥œŠ¢×Hy9>“dı‰s¾î™.wBOgò+Â‰şJ‰å%TÉQÀ ÓD—\½Ï|ßš6ŒGÁQR¦}A‹±dFÇ…üŒØ5Bİbš…fS7¸C]²%2ÓQÂw
YºÉÚ¸šç3Ğ§ıBg˜çï*7Óbp~®]S¡Ñ€Ê:\\ÀN4-èÄ¸ó·Ä¼E-±õ…  îí=œ5myœs@Â-£ø(bÏAoø®İ=<y7ì·ÿÛjlmíìlooÕÇ<lı|v”Á¼=€_ÌéÄš b?U
…B&¸Ö—ÏõOš§RşL¦G¸«^}ÊTëå¿N‹ùš®››9†s(®AÅ
 dÒè&‰ı2}â€Ú¶uÇ#_I9EÎĞŞ…QÃØñĞ1"£íû¨S‡Úªª¤-jÊc<¶qhs2½¡«İlzE¯âBvK›-Û ­bÙ¸òõH¤p9äşÏgnÌ™IBúìrŠ‘wè›²Ga]Æ$‹0xÌ~¡´écP“ğr1ƒ
wÀÏ„1…²©vEá1ír¦zˆ
¦m&‰$RíŠ	Ô!G}şîıùª	
EUjk°ñåš –İFDû|j_Œ·”qÒ²ÙµfÅÖß<ùi÷f{¥À„=SÜ- —±@Û}•ÒE*=tö;öVÑ!à¹9oñu:‡uMƒÔ*@ùßã}’–ÀõËpÁN°÷ÉìÏ8}U«Ã­šÛû›­î÷v·58œtß6TE¦‰¾rG`ñ0¸sì¶xÛî´æU™_Š”¬*£lLË±‡~¨ë˜{¥iQ]½öat¬™Vè±<(i‰„hbR*³YİM1m˜¾6²2hv’q¹8:&rÉ(¡Ç¯£_¡Ç%‹nÈxCÜhfFŠ¼îúyQÕ¨bÇ},ê¡İN³Q	ÈY·Ó>nZ‰\æeâ½èjP?3¶´K?ók«ÕkvÚ¿µ {rØê4ÿÀ¿ß6{qáCEˆ—£]¼?ë·NgJo ù±´w'âLÚ¤4®BC)Ğ!n.ş|¢<xÍÅ–ÑbŞO	:ˆ}ÊºãNÅ™íàº´ôHÜÉd	¡;¶ÍD ^C¼¬•aÁ¾{üo©¡­-±´Ğp“ñ9¦f\b¦”@Ì1µ;æ'ãËôŸ@-ÑdÂë£]ût•æP–©–¢ü§ªvfŠªˆs~6ÒÇ ¶ª¾e¾‚Îè±©ƒYL¢YŸjd~vÁ%ƒ9é`"UŒØ¼b–K¼1-ô‰fSŠøÌSwxM¨¹¨^¬¾4¤C”Õj"ÄáœçX"é]§i§Z OàOæ9€`SªÓ‘¾§é”câÿ+Ã\°¶Æ¿h¹ôÃV2Ï¬½Ñ¬q"¬]G”FëVh AîÀµ4’5ó¸,˜±KÓ¶q‰8cŞe¡Tá'äÄfßE«@v4JáS-ÍKûH2Òà‡%3eç9Hhğ¥ ÊSÇ—Ì{ì9S=6=?à8\˜ši‹5¡f¹d¨Ó´C¥!ş°R8œ,’"[pBÛ@-{¸º‰MCñS$ÀX;5	ˆ’w	’&öQÖ±\PÇÀLÁ"†á‘„èü´v8‘"c2¤EÜ>Qy‹ ÂVP´ÈTOt'ék–ïğIıŠİİ8ÇÍŞpp2ìœ4;p31ùº¸m™?@”–öÎ^ÚªOÃF0&˜ğïü€M…)µÇœ‡Íæ‡P˜6¡|…SDŞÀ•¢¡Àì
Úı5:Ø%J,Z	ÇFAZ6jQ1Š=(oÎ	9o.ÓMd&Zl¿Õy[å>LÊ“u¡Ÿ>†ADRš†§.çÖ¿1IĞ|É˜çİ`-J¾àL…¶ã9ÉÚu¬Yªp(hD’¦Ic]pt 7µÔ¼±QzCA´rÍ~"Z8S´ã©‰„…xg4ƒ;é²<šÈÕGq* Š‰ÇT+›h›Ety\ÖÄ	T)Ï‰±Mñ@¡¡‹:Üå6ÅÙbm’ÖĞ~“Lœv-¢È:|äË#éáPœ6Ôä˜{-:,¦²õø$:¤{Â›-ó–ñÎ?m^pœÅ~¬@ruşäÒü©uùŠòG+rvËtÈVSï‹5ªŞëTF½/nAE‡MØßÇßÛ¼H“á»ê’wjæ8E¤>JNY[İ§*…Ù¼:KìøUA+…—Úœã‰=>â’ùEŸL^Ü.†P=Rè°C”ƒÑ¡ğ²ÂUÔ¤Qıº8gyÏ³àıı¹e¥‰†A…ñ*÷K–¹rÉ¢f'éq¬Ğá#“*sâÊx¹¶QD¦ÁãØ’ã•ØzŸ,cñ¡ÁW<ûéNzŸyŞóÎ~qe5$‰6–ˆS9já€3¸ é–àŠv b‰.¼¢¡òxÓly	uiB‰ú×:B9è´šİïXyüIDÑ)RˆÆ{à<P\AxB?{«â|dZ˜ pš_Ù)ÎÚğ:ÅÏÍƒ_íA§ÕPiãÇ`L<'¼œ¸¡Øí}¨@_ÄLmÆæeèi\jşBxœÖÁ zÍÓæq+ûXi—¡9ÄºE?¤-˜«ï·fç¬ÕoKÅ{AC~Å¹ªXÚˆY¨¯p„Ù¬Š,ĞÎHÓ¯3°èï>fzË±~ê’WLˆÓÇ@X3NA}o÷ùˆ\<ËÜ¿ÇåAmv6q¯çÈjûwU^U× VP‹©ÍJ…ömB=çæ&àëipnœ_OÁoí?GôıçuÜ¢o•ÇÅÿÈÛüÀ2~.¢ËŸyJÜÆ‹÷B¦3Ì5µ›+øñ_[B±6û±œG”¯Á¬æØTx¾BZœbm}ÚD¸³$n9aúÕP@È¬ÔÌ·@Œ¦Q_?)†áÌ°4ôîqõğ 7&Oæñp?î]²aè´ÉˆZCª8‘0Vl•ÿÉX9£ÛSŞ_F\	Âñqœ>f(]¹«›îæ»§$^ƒ•ä,eÜìÅv±ıék•Á÷¶Öôæ­ª´ûÃ~ëô·Öéğô¬ÛmwªR,E¬¦¤q,Âp”ŠĞqŸ†¦sMïD2àè|*±/àñ£œ¢›â,K7J¿²tÓàsèFÇÍv7®ÈĞÅ63Ï´që.ÖÄü‡­·Ãö uÜP+K*&U¤Åš:?Èét*mE®uû”0G¸crÀcf‡	Kf,½BZá{¥«]›—tt&ß×È‡çg½8?<y×½xyŞ²æ]P¥,Ã"1ïW	şË¼Š¢Â2“¤Ÿç¬ú¼2ãƒÈ"¯üF@Œ±[âc .<yS%3²üºŸzİ¢ö£FÚ†Æ¦´¼.y“¢öS¯QÒp¢î¢°Ë_$q’?#—óÛ¿Ìçì•e¥'|nòaÓëğ§M¢*äIÀœË×Ëq/}óç¡)‡ñÈÓVÌ#°’'&ë¿|ŠCåsÈÏ€Å[¥ïäÎ—¯½µxÿÓn—şlÕş)ïµ+F%ï×}ÿûj{{áûïúëÚƒ÷¿µÕûßoÑ’—*»©‡.Uİu•ÂOr…¦eäFU.ŞüşûŠox¢óTÚ¹7ò*‡Od¡bşÉè†tÿÀuûOt‰Ã”?<Æâ±¶›®"Ì—òÿ¬^ÿÿßªmnçük«^[ùÿ7yÿ¹è,NáŒÕÉ¾’ôûa:Ù®Àœ²lÏT&9´;#ƒ)k˜ÅÓMh¿utÜêbfÛ<îuZ}LT±Å£İ³ã¡„èó§'ŠÉ/±j ˜ê/ù=-¬ãïëó‹²r¯hÈr÷€_ia‚¹§ÄİCtKÇ_#ğ#;DI½”#P5¸ÆÔS—¤Ò½¶èŞ‰v2ñÂ4ğî°¦)0âÑÿ`w—B¬ôolv™‘’JÎ§¾„Jí%¨İÖ;µ¼—Çî:(Óu›şm ªìk†A½%õ—³£ÖpñÕ~û¨Ûìtså€î„ZJAàp_/¥Ç©?„¹rBGGWX/´|Vª}9•Y¦ù™qüßØr°V_GåĞå¸ ÊûÎsÖsÁqBzÇ©Q*-êæGóÔÿ˜mH=Gƒ¸†@“H5ê;74“SÁ?o2&‰=/^ĞÃjR6Ú‘±»«Óç›7 ¾CISØ·tXa¯Iÿp8œÜÚX’!œ"ezÉÜÄÜpîÜr±SL/æ/¸ w^è"¹òœ*—f¡u¾xÁ¿gô”DƒXq‡ôdsÊæôú–tñj»/¥<'Y†,y˜‹Êõ²9VÜ|ts:ù”n¯Kñª¸Aˆñ|9rMÏÓî¸!ú¹Ùªs¨’PÆË¼ÎE2ûÊ>=.–æ1ŸÁ÷Kˆ&ÈÂÓè»$!ôgPÅ3:íÒ'¥˜UÌ¤Z·:ãğœİêhFdDÆîêÍD£“äœÙ"I¡g“oÍV©Øª­Úª­Úª­Úª­Úª­Úª­Úª­Úª­Úª­Úª­ÚwØşÛ(ñ P  