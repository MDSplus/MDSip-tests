#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1259825078"
MD5="c30d05d217601188ba8d753de8e170e2"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4056"
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
	echo Date of packaging: Fri Apr 22 15:30:28 CEST 2016
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
‹ t'WíksGÒ_Ù_ÑY8È	$ÙW’Ñ…HØ¡!J 89YE­v±Ñ¾nzDá¿_÷ÌìS€ìÄJruL],v¦»g¦ß=3×Ø|ñìmÛÛİ]úÛ|»»•ı·ÍÖÛ­7;­íİ7;/¶š[;o[/`÷ÅĞ¢ Ô|€šcøL[÷Ôøÿhkl,Œ¼F0û³äßÚyó¦(ÿVk«ù¶ÖòöVşfóÒt6ƒ™¢”İ™!¸0ßwı@AÍ€:S”Ñáio8t»íJõR˜£ÙÔÊ–Z“c“£Ş)¦ŸRØçú!Œ;§ºãÉ÷'£q»òùÚk[®®Y37çàáÉi˜¾öÚÿ@e)Â†''ıîµ7CÛÛ´Àô&!#âÊñÑhØ?‰u>d¾8
üM¾Bñ¬(˜xo˜œs>q¢ñúG“~ï»ÓÎéO“agü}Ş2/÷* dº+4LE9êuú'Ú†©Yî•¢(o:ádÆ,¯ZƒE×Bx÷º'ï•³@»b{PIeõ:œ»^hºNpçºkÛ¨»Š¢É¡ø³.Zò9ûµ^§‰j·+Tƒpf@İ¢+öš¶“B“ÒÌ¿a>ğ}†.\2ˆf@Õ`S-²B.ÉZB#@çºV-Gƒz 5Š(¡ë3ìvB0´PK)$½A¢¸†K7`’l0so!Ğ}ÓCânäëL~Å8ñ_É±"‡ê0ò!äšè’»X £cğ;Óa¡ñ$8rÊt®bh1–ÎèzPœ»O¨[LsòĞÌöÂ{”%KPb&39|¯F¡µ”Ëài~À@·ú…62?ØSng¦Åàü-¼©B»õ¸¸€}0ÜxZĞÑAˆq3YKÒRõz4·T×—‚ŸZ:¸¿ÿxÖ¬6,EäîÎ	·ŒÜ¤pA‡ÃÉÇŞàèäãdÔûw·½½½»»³³İzó¨ûİÙ‡nèGìüò•ÎÌé—1 ±S¥T*å|lkõ,Ğú¢yêµß¸èK®×_2ÕFí÷Ób¦+†ë`Œ3§p•2Ô­š@*f’ê/Óg.¨=Gw}²•ŒQ4àõ](5L]=2ê~€2Õ¹«m¨JVs¡©LÑÇc›F‡ Õ›xZ8ãŞÁìkr|uò‘m¾jl“BÅªq?âû‘:HîrÂíŸÏÜ^0“„Ø•w˜¿°'a=Æ$‹0>6ô™ó4(BiöSP³èjùn€·¾2Sre¶vMî1E9Ó=BS˜I|"±T»fuÂQ_¾\û‹›)
yUjeØüzMPË‡Ñ~;µ¯¶¶ŒrÓú¤f³ÍJ´¿õÓ¯'bíTP¥A™
7Ço0Œ<„ºÌU¸Hì’§M½á<§éäÒ°ÇÆ8…¼Š…ºH”oP’†ƒGf‚½4%x©Äf_ùF] ‡‹â°iBP>E†$ÂÒæ™A`j¢æöásíI/X3ö~öŞvÁŞÎÆ÷¦p[(Ïd®‡Şh2êşĞ=œ½Á‡¹*,ãùì“	fä¬ãO¶‹{ƒîøhrx2xßV™ÈÊC#P@“ğŞ{”´á}¯ß]äöe,’Æ†Œ	-×™‘®cv˜¥E{GEĞ©fZ‘ÏŠ $&b¢‰i³Ì·u/³hÃ´K+‡æ¤9¡ç»¡«cª™z’¸ú5ú„tÓméñˆ[ÍÌÈ×½ Èª&-`¤{(k2!9ô{Ç½q7e‡J+Kƒå@D#€FY˜©¥]y˜u»ÃN¿÷C'Gİ~ç'ü‹ñâãig˜”fT&ùÚ•‡34™¹Râ!®8–õ);³¡  )•†‹ĞPJÒR1ü‹‰r'¹[úšEY•p("©uÏ]–‹Q*òhh‘ke‘£»ÃD¨(#^^ËĞaßş·RÑÊ+4-2¼t|ªW˜Ë¥Tíéø*ù§P+$™®õI‰–¿\¤”U¢¥ñ¥¢-Ã\Qq@ÂqFèÄÊ0¦ó™Q¡1úÌv1ÏJ%PÏY8g0kÏ¤ˆ›×ôr‹·¦eaÑJ¢Ã€YSrá.¯Z5Å‹õ¡†´SbH€ònM¸8œ3ô]K¤å4­­…ú~a¾fÓIÒ÷5ÒwìBü¿¥pX Vÿø5—>Ø†BêyèÚ”ãDX]_R¢¯[‘
}y¥é”Nj˜i&h¤é´øKveŠxXwÊ»,4€üäFœ˜Áœûx¸ŠŒĞÔ#Kó³6’Îƒ„4L$–Ï”Ÿç0¥Á·J ÈO³pRï©ïÚzjúAÈq835Ó{BÉrÎP§éDèJ#üaep8Y$EºàFRö1œº³MCö“'@_k›¡ôDÉ{IÈë„/(c`&‚àq†á‡è ‘¤Nd_’ 2$EH‹¨¼G¡+ÈZ\T˜Lt/ékVàòIıšİßº¾Çád|2éŸvúp;3ù¾¸n©?é”–úÎ^êj@ÃF,L,"¸BfUêMùn5‡“aº„üF[Š†sê¨÷7h`WÈ±x'íi9(E¡ÄÈ"´ ”½#äkó˜nâbâÍºı÷nÃ$<Y¹Ùƒ"D$¡iHÑöøjƒ[“Í·ŒYâ-f®d®-¤ÌIÚ®cUÕ€#A#æ4MšÈ‚£Ë|1;o¢”¾ëR ˆw®âHRx×F=¶M$,Ø‹Ø8£ŞK“åŞDî>öS!Õtl:¥jŞDİ4È« Éã¶fn¢HyşHëaŠ;
MÔåª(Ãwd÷`ˆ½IzXåa0soÙğ"ğ+ß~âI&âü¶­¦çñåø”²’Éõ“Ûš•gĞùBtõ!ôâcñ%ÇÔyì§>ûüà³>÷äà3<3`wL‡|-ö©Ò¤ÚêS¥EEØ§Ê6ÔuØ‚ƒü½Ã‹Aé¾[™.y™¢æ|Dê³¤(«¥L¥0_T¥‰ˆß´2x™à¼OÄø"V¬ˆ+æãUíğên9„òä9Õòb±,kÌø4û÷ÕË¢ËæåÉÎ'>,¬¯¨NE»BHš×ÏS]—åÉ‚¸)H2èÏ:/	f¤¬ªÌ¹ëÓÕÚ„œ4î'W{¨´úOénW~ü¾‚g9!O†¿ñ´ì:9sÅ…ß„¤Ñ^!
å\ˆ”Îá‚$S…kŠ•*]ÆCµ}ğíl~ıuoÅRS÷ógâa¿Ûü……Èïá„§¯’@{üGˆl’æ$Œa”¿›q†3,LR8M2¬g<VşpÖƒ¿ q|×9ü×¸7îwÛ*%'èpÂ™ïFW3/I u	ÿƒé×Ô¼Š|B-^«—)	ëaØ9í œ
í*2ÑIYÈú	¥	\|?túgİQ»R­<B]êîuİÒ.™…òŠ.1ãVQ‚%º»ÔôëĞ-º}H=OÆåØ(sU.&Äé ¬kmP?9#>"·'s·ìŸp{ĞÜ…İ-ÌG8²:Äş=•WşMh–ÔJ&.ªPÂ¾-h¥à\İ|+Î•á[øíƒ—ˆ~ğ²…ÑğåvMq½°]ù§¼CÃh#Xz½ì¨r¯<Î1Ön¯áïüò*ÍùßkEDùÔã	Ìab°á9IÑÆúFˆ¸±¤f¹ ‘˜y”ÊÑ6~’Ã™a¥ŞçâáoJ–Ì}â”\ĞU%ºO‡ThQ`&	UÅH«Êú¤¿œÓ4ï'·)A8>!Ób·ã@®t~€Ga9Av	TåL5Ì"*g«§÷+Â_q¿Ù},Ú/]À<J1ÚªR©ÆË-¤Oi~§5t4©¡
İĞ«›8¡J[ğøQËĞ-¤®)İ8ãËÓÍ‚/ «ÊhzÜéŠn‹^„›…¹ZhSÌÔ}?é»Çmµ^—>¥nRõ\iª‹N'èVìğºwŸãîOwL†xÌœHâ a¹€yLËÄˆvøIh7æóÉ×JòYÌùÙğÎN>.^ŸwùTÕK÷H‹„NÿåšQœ«Îš})Şã$”â¹›å¿Ğ¢¯İcq}Ì›*C®+ˆ¡G™·Bê(¾¯EçmhÌ¦í%péu”yÛ“…[â}—¹_ş'õ—üQXp­æøÓ¾¼š¬J…ÕíCÑb#`]şPLT°<¹Xàz9ğF-é¥oşø=5å2>ésV‹¹'VŠÄÄÅÂ×Ou¨Ôøyµxùõ¹Aç{Gk­<|»×šó$ZùúïµkF•Şó¾ÿ}³³³ôıwëm³øş·¹İZ¿ÿı#ZúDe/óÂ¥¡{RúV†œËÈ´ŒÂ¨JÃ•‡ÃœCåEåÊ·Pï&ÈË¨÷¿…ºul'—?£÷	=o4óE—ø16LùÃg,ëI0[y±n_Çşórıì{{ûmÁş··wŞ¬íÿyÿ›è;Ì£]aŒÙ’ö¡aºù®Ğ´Y¾ÇÖÂYí>Ø,Â%`JNº`u?w˜„u‡ıîs*jÉğàìx"AFüI‡bò<Ìpéf1úk~ÿ	øûæü¢¦<(%²\×;äWE˜í+%q§´"ºıâ·ücüÈQÀ¥€r$j„7˜&é’T¶×İ»q(oKCÿóïR	]ıÿ	ööÈ‡ÁFHÿ¶Áa·©ªd}êk¨7_ƒ:è~TkûEì‹Lİpèß6¡úfÔ[U¿?ûĞl!¾:ê}tú„g‘Kˆ4—Q™œvGyJ¥’bH·¶K	g:›$¨qgRÍbQ<şÄæk)m-dÃÈ
Xµù›È	¬Ã0åÍ1,Ã¦<O
€œ'œşoj¹Xèn ¦Ğ¸Xï;/èò_µÑc•X§¤Åİü|œú_s©tñ n8Ô$çğÔõ¹Ö›œ
şy—³ìyõŠŞw“æ¡R{{:]d¾{êGÕO#q‡eöšô‡ÃÉ­}%„Sdì ûg1÷Ï8wa»Ø)¦ó—ƒÎ¾ Ç\h¯1¹M2ãçf©w¾zÅ¿çôäDq‰”è±È_)ÿYP‚÷$‹7;Õd+µEè8É*d¹†…¨\.«Á-F7íEÈ§tE]MvÅBüHæ+ëø¾vÏ1Xºší‡ª
a¼.ÊLP$İ¯Ğg©Ç¦s¬İ-^ŒXıkˆ§}-LGP6JİU	ø¨?Æã(ï9é³j²nLòºw:ãe?¼dw:êiTN¡±»q;Óè\¶ ÃHÒgaä;dhóu–¸në¶në¶në¶në¶në¶në¶në¶në¶në¶nÿ¿í¿ê¼mÏ P  