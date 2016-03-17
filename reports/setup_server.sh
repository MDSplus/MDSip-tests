#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1487729838"
MD5="6a7ee839f70a4157c179527edc910de3"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3948"
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
	echo Date of packaging: Thu Mar 17 12:33:16 CET 2016
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
‹ ü•êVíkSG’¯Ú_ÑYt„-ØW`qQ@&ª¡B"N(Õ²;BkV»{ûà¬ÿ~İ3³O$}&ñUi*1Ú™î™~÷ÌT×W^¼m`{·½Mkï¶7Ò£¶R«¿}Wß®Õß½ÛZÙ¨ml½{»Û+Aı@ó V4Ûğ˜6î©ñÿÓV]÷YºUüwÉ¿¾ùn{+'ÿz½¶±Kù¿x[ıaıÒ´×ı±¢¬»3pl`çx¾‚š¦(ıı“voĞmµÅÒ¥æ3[›0P‹jYÚ'8f˜^jHaw®ã0h¶Ã_ûƒFñ!õµÓ°]³ÆLsÀ½ã“0}í4ş‰Ê’‡ë÷;	 ÿÜi¬w}bø¦;Wú½Îi_¬ó!õ…À¡ï­ó…Šk…ş”ÀÛ½,à”ó‰U:ÃNûç“æÉÃ^sğKĞ2/wŠ9 Nt&x`˜ŠrĞnv†©YÎ•¢(®gÚÁpÌ,·T†E×xÿZÇ”S_»b;PL¤g˜í_À™îL&¨ªŠ¢É¡è³"Zü9ş\©Ğ,eˆÚJ=›>P·èŠ¡]„&ö'Ğ¤#>ón˜\.—BŸP2ØH­€®Óğ‘†ï:UÎĞ @"
~àx»í -ĞJ9Á&Do(®áÒñ™$ë[ğuÏt‘¸z:“_NôWr,Ï¡JŒÜD ™&ºäî}æûÈèüÎ´Y`<	œ2í«ZŒ%3:.ägÄ®ÙêÓì,4›¸Á=Ê’Å(“™¾WHĞ8VWÁÕ<Ÿ>1èšpÀ<G¹›ƒ³34èš
TÖàâvÁp¢iAG ÆÍx-qKÔëÑPÔEŸBniîàîîãYÓÚ0‘{7$Ü\0òŠÂãì÷†ÛİƒãÃ~ûß­ÆææööÖÖfıiÌƒÖÏ§‡ÜÀÙ#øù+›£/c@l§J¡PÈ¸ÔúâY şEóTÊ_¹èKŒ¥×_2ÕZù§Å|MWÇÆfàŠ«P±¨©4šI¢¿L; ¶mİñÈVRFQ…SÔw¡Ô0r<4`tÇ¨û>ÊTç®¶ª*iÍ…š2BmÚ‚ToèjÁ˜»v›\“ã«¸dÓEcë'{!ßÔAr—Cnÿ|æÆŒ™$¤Ï®&èy‡¾ù'{ÖeÌ@²(ãy°Çì§AJ›<5¯æ/Páxë™ã€0"W6Ñ®Éİ¢#¦(gÚ ‡(`
3±O$–j×L 9ê«WP]O¾ÉeR[…õo×µlŒíë©}³µ¥4—Ö'Õ–İhV¬ÊøÍÓšvošQFò:Ø3ÁP ¹¼‡ºˆåUÊ }¨ô Ğ]Ø{¤ÉØ[Em‡WJd™ÅÔp¨ñÖ5’™ å3óƒ mê·Yqh3V‚½Ï^1ÁÎXñéÁàÑŠ§/ªu‡™‘Ñ½¿Yë~ow[ƒƒáşq÷CCUdè+±{Eƒ{÷Q(mÀ‡v§5ËcÊäQä[UéBcZ=ôC]ÇÄ*M‹Jèµò #Í´BåAIJÄD3N™ªênjÑ†ék—VÍNÒ)×sGÇ,-%ô8ª:ú5Z\²é†t–1Ä­f9f¤Èë®ŸgUŠpRQ…2ÍF&$ §İNû¨=h%,p™7”Yõ| G¢@ı4ÌÈÒ®ü,Ì¯­V¯ÙiÿÖ‚îñA«Óüÿb%õñ¤Ù‹«ª0¼íâÃi¿u2U
<:äÇÒÖ°3íhsRi¸¥ @‡9üÙD¹óš‰-½Å¬ NÙ7ì‹ dİs£ÇÊËv0„.í-Ã”¬tÇ¶™pÄ«ˆ—Õ2ô#Ø÷€ÿ/T´Õšn2>CÕŒ+LƒˆªvÏüd|‘ü¨’LÖú¤DW¿\¤9”E¢%/ÿ¥¢]…©¢*â(wôÑ‰­Â€Jk™Œ 1zlâ`Š’HÖ§˜GpÎ`Â9K#6/‡åoMË}¬Ù”>³FäÂ^ği.ŠK+i'Ä ¥¬špq8gà9–Èh×hÚ‰ècø“y Ø„Šp¤ïi:e¾Ø…øÿHà0‘,œñ/j.}Ä°U…ÔskTkœÓKÊ‘u+4P¡/ïÁµ421“´4É®LÛÆa$âŒx—…P…?œ3˜}í—£Q~˜zhi^ÚF’y?,˜);Ï~Bƒo• Ÿ:&°¤Ş#Ï™pè‘éùÇáÌÔL[ì	%Ë9C¦¢+ñ‡•Âád‘é‚ÚJÙÃpBèzÄ6ÙO }íÄ¤' HŞ%HšØG^Ç|A37ˆ+08DGr$=°ÃÉ%	2&CRÄğ´ˆÊº‚¬ÅEñD÷’¾fùŸ„Ğ¯Ùı­ãpÔìÇÃÎñ~³·c“ï‹ë6A‘Úñ3AÉ`©ïÜè¥®ú4,`ÄÂÄ"ü{?`¡Jí_Ã­fó&L›¿Â("kàBÑavõşì
9í„c£½ -¥(”Y„”°7g„|m.ÓM\L´Ù~«ó¡Êm˜„'‹>?}Æ‚ˆ$4)N\¾ZÿÖ$Fó-cw‹…&Ù‚3Òç$m×± ©Â qš&eÁÑ‘\ÕRóÆJé9‚hçš/Nó„·p&¨Ç	ö"6Îh÷Òd¹7‘»üT@å¨6Q7ò*hò¸­±(R?ÒzD˜âBCu¸*Ê0ÅÙ=bo’È~ãŒ[v#¼È|æÛ=éÁPœ{6Ôääz5:à+¦²õø^#:1yh›=¢ujûÌúùÙÅó³+çç–ÍÏ¨™Ÿ,˜ÙÓ![kTßœëT7¡¢Ãìíáï-^fI\OuÉ‹5sÚ!’—9E£¬R¹ştV¥$bvUĞJá¥Âë|<¥óX‘*-˜QôñÄ1àõİ|åÉC…Î"DAÙ.*=EUU ó³sÇîíÍ,t¨¬L$4BŒ×©ß²P•[U·8è³X…ÎI™T™ÕVF‹¥,2î‰ü*-ë<ÙÆü²ÿOoúƒãŞWØüE§7¸NGØ©œ	±pÀ)\wKpM1¤X¢Ë¨h¨¼Ş$[^@]ªĞÿDı¥Aö;­f÷;¿à^´D‚¬ñ”#S–ĞÏ^ú€8á…†pNó…âğ´ß¡QüÜÜÿuĞtZĞ£³Æ^İPD{*Ğ¾““‘yz„š¿¬]¥¥µ?€^ó¤yÔÇÚ<ÚUh±2CÖ)sñıÖìœ¶úb©ø ¡Ë¯8×K»dÊ+¼Ä|TE	è†åRÓ¯3°è’í!^ô4—cıÔ¬˜§°ê›€zn÷ùˆÜ<PË\ßãö ¶Ûë9²ÚÃş•×Å5¨Ôb*X©PÀ¾¨'à\İ|=Î•áë)øÍ½Wˆ¾÷ª!êÕfYqÜ Qü—¼œÁ,Ä7à"º›™õB Äu¼ø x:ÅlQ»½†ø­"kÓËyDùdà	Ì:aL…ç+$Å	VwĞ§ Â%1Ë1Ó¯‡òAæå$fÑ›F}ü$†3ÃB×»ËÅÃŞˆ,™ûÃ|ş¼t†®Ó&U Z¨Üw©fDÂXsUş#}å”.7yq%ÇÇqú˜"weV	6İÍ£§$Şƒ•ä,eö"Ü£oş^e øŞöšŞÃ¬½âF•vØoüÖ:œv»íîaCUŠ¥h©)nE+n8JEèÀNCÕ¹¡7p4>•–/àñ£œ¢›ZY–n”~eé¦ÁgĞ®šínŞ]‘¢‹03Kµ1tkbşƒÖ‡a{Ğ:j¨•Šô%“jÊbMíät:W¶"G×º{›‹=Üà³C‰ƒ„å¦,½BÚá¹ÒÕnÌ+:ü’Ï_ä;‹³ÓŞœì^¼9kÙó.¨Ö•n‘ïW	şÏ<U¢Ò0“¤Ÿå´ú¼G2åƒ¸Dî^ù/ô€èc7ÅÇ@ÜGò¦ÊÅËò#è~êñ‰ÚîÑi›Ğöb¸äÉˆÚO=IÃÍñºóÜ.à‘øIşÊC,¸œoü®/¯,+=as»w£˜¾X‡¿<U!Oj f¸\¼V{é›ßæ£‡¦Æ#}Nk1÷ÀJ˜8nÿö)•Ï!?ÅO‰¾“[[¾w´ÖâÃO;uÜúì÷ŸGÚ5£êêeß¾İÚšûş·¾õèıgmóíòıç_Ñ’g;©'Uİu•ÂO2d\†¦eäFU.>ìÿşûŠïyLı	*íÜ…¹<ò‡JçñI¨XG†|ù	½‡¿ïºı±'ºÄaŠeeÙ^ğıwV®ƒıoÖ6òö¿¹¹U_Úÿ_òş;2Ñ÷˜;Â«ã=%é÷Ãt²]9aÙ‰Œsh÷şz.SV1a¤k³~ëğ¨ÕÅ$ªyÔë´ú˜a‹G»§GC	Ñçï“ßJa‚J?0	ÑßğK=XÃß7geåA)Ğå8î>¿ÿÀ\fW)ˆ‹ Ñ•¿ºàGvˆâ%½“#P5¸Á,G—¤Ò½¶èŞ"™xkx÷˜>
èñè9ùÎÎÀcÖú·6»…ÌHI%ãSß@¥öÔnë£ZŞÍcwäéšMÿ6€Uö4Ã Ş’úËéak¸øj¿}ØmvºiY@ˆm¥ p¸­—ÒãÔ?±¸rBGGSX/´|Vª}9•Ùf”™qüod9X®¡pè&Uå}g9í¹àqBzô‰Q
-êæ§ÀÔÿ˜mH9Gƒ¸‡@“H5ê9W4“SÁ?ï3*‰=¯_Ó[6ê‘±³£Ó…Øû÷ ~DNSÅÑB˜xc¯Iÿp8œÜÚXrA8EJõ’¹?‰¹?áÜ¹íb§˜^Ì_:ûtA‚ĞD"rëd9UÎÍB!ê|ıšOéÉ‰ü
bÁĞ£ƒ5¾Rş3'×$‹·[¥x+åYè8É"d¹†™¨\.‹cÁÍF7'³Oèª³ïŠ+„øÏ—#×ô<í+¢?w5›uUÂx“—™ Hj_Ù£g¦R=f/C¬ûD
daiô]’ú3(â)¬èãR¼TÌ²Zw:ãµ1¼bw:ª)QF‡±»z;ÖèĞ2§¶HÒcAèÙd[Óe~¶lË¶lË¶lË¶lË¶lË¶lË¶lË¶lË¶lË¶lË¶lËöµÿÌ…9 P  