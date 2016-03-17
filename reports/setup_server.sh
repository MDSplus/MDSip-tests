#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3660446622"
MD5="77854e623dec1c1f55b400227d42fbc1"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3957"
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
	echo Date of packaging: Thu Mar 17 15:25:32 CET 2016
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
‹ \¾êVíkSG’¯Ú_ÑYt„-$W`qQ@&ª¡B"NSªew„Ö¬v÷ö&XÿıºgfŸHûlÇW¥©Ähgº{fúİ3Sİ\ûêmÛîÎı­íîl¥ÿFm­Vÿi·¾ÓØ­5¶×¶j[Û»5ØYû-ôÍXÓlÃcÚb¸§ÆÿO[uÓgAèVıÉß%ÿzcwg7'ÿz½¶µ[+ùõ¶şÃæ•ioúEYöÁÀ±yãù
jT˜¢Ï:ıa¯uÒnKWšÏlmÊ@-n©e96:êœá˜az©!…}p/€aëì¸=ız:6‹©¯½¦åèš5qü`–îŸ¥€ék¯ùOT–<Ü zÚM ùç^s3˜º›SÃ7İQÀˆ¸rr4èwÏb©/}o“/„P\+ôgŞéggœOœ¨Ò=u;¿œµÎşõ[Ã_ó€–yµW|Èq¢sÁÃT”£N«{zÜ4LÍr®Eq=ÓFf¹¥2<(ºÀë×Ğ>}£œûÚ5Ûƒb"¨TàÂqÓ±ıK¸ĞéµõRQ@49}VD‹?'+š¨Q»FÁÓê]1´‹Ğ$šÔÄgŞ-ó€‹&pàŠAè3Jk¡pÙ•c>Òğ]Ç±ÊÔ¨CDÁa·€¡ZB)'Û„è-Å5\9>“dı‰s¾î™.wBOgò+Â‰şJå9TÉ‘§ ÓD—Ü½Ï|0mO‚#§Lû:‚cÉŒù±kş„ºÅ4;Í¦np²d1JÄd¦#‡ïÒ(´õup5Ïg Oú…V0ÏßSî&¦Åàâmº¦B³	•¸¼„}0œhZĞÑ%ˆq3^KÜõz4µD×‚gZ8¸¿ÿxÖ´6,DäÎ	·Œ£p:‡ıÑÛNïèôíhĞùw»Ùhììlo7êOcµ9?Îà^ÈÁ/^éÄb;U
…BÆ«Ö—ÏõOš§RşÌE_a8½ù”©6Êÿ;-ækºb86F5sP\‡Š@H¥ÑLıeúÄµcëG¶’2Š*œ£¾¥†±ã¡£GFİ÷Q¦:wµUUIk.Ô”1úxlãĞæ¤z#W&Ü»#Øô†_Å…l,›-Û¤P±lÜù~¤’»qûç37çÌ$!}v=EÏ;òÍ¿Ø“°.c’E	Ïƒ<f?ŠPÚô)¨Ix½x
7À;Ï„1¹²©vCî1E9Ó=DS˜‰}"±T»auÄQ_¼€êfòM.“Ú:l~¹&¨ec„hŸOí‹­-¥¹´>©¶ìV³bUÆoÙtú³Œ2’×Á)†È¥>,ĞE,¯RèC¥îÂÁ#MÆŞ*j;¼P"Ë,ş ÎCç°®iÌ(ŸœwiÌP¿ÌŠC#˜³ì}öŠ	vÎŠÏ†V<ûªZ‡q˜İû›µîN¯=<öŞ4UEæ€¾ò»Wdñ(¸w…Ò&¼étÛó<¦LE¾U•.4¦åØ#?ÔuL¬Ò´¨Z~ç(:ÖL+ôX”¤DL41ã”©ªî¦m˜¾veeĞì$r='ptÌÒ’QB£ª£ß Å%›nJgCÜifcFŠ¼îúyVÕ¨Ç õP(ÓldBrŞëvN:ÃvÂ—y#™U/z$4HÃŒ-íÚÏÂüÖn÷[İÎïmèµ»­?ñ/SoÏZı¸ª¡
ÃËÑ.>œÚg3¥À£C~,mİ	;Ó6)•†‹ĞP
t„‘ÃŸO”;¯¹ØÒ[Ìà”}Ã¡BÖ=7z¬¼lc@èÒ>Ğ"1LÉú@wl›	G¼xY-C?‚}øÿRE[_¢i¡á&ãsTÍ¸Æ4(˜£j÷ÌOÆ—É?Z"Éd­OJtıÓEšCY&ZòòŸ*Úu˜)ª"Nø‰Ç Ø:©´–É£Ç¦¦(‰d}*€ù‰ç&œÃ‰1bórXnñÎ´,Ğ'šMùgà3kL.ÜáŸæ¢x±´ÒvB	PÊª	‡sc‰Œvƒ¦j>¿˜ç ‚M©Gú¦Sæ‹]ˆÿiÀÂÿ¢æÒG[UH=±°FµÆ‰°0½¢Y·Búê\KÓ)Ó0I‹ÑHÓiñWìÚ´mF"Î˜wYh UøÓ	91ƒÙ÷Ñ.p9åç©‡–æ¥m$™	iğÃ’™²ó&4øV	 ù©cKê=öœ)‡›pÎLÍ´ÅP²œ3ÔiÚ!ºÒX)NI‘.8¡m ”='„®GlÓıä	Ğ×NÍ@z"ä]‚¤‰}äuÌ”10Apƒ¸ÃğˆCt*GÒ;œ^‘ c2$EH‹¨¼A¡+ÈZ\TOt/ék–ïğIı†İß9'­şhx:ê¶ºp71ù¾¸n©?”–úÎ^êªOÃF,L,Â¿÷6ªÔó5Üi6?aÂ´	ù+Œ"².fWPïoÑÀ®‘cÑN86ÚÒ²QŠB‰‘EhA	{sFÈ×æ2İÄÅD›´»oªÜ†Ix²èóÓg,ˆHBÓâÔå«õïLb4ß2æywXh’-8S!íxNÒv’*	§iÒXÀU-5o¬”ãP ˆv®ùâ4OxgŠz<5‘°`/bãŒfp/M–{¹ûÈOT±ñ˜
auÓ ¯‚&Ûš8a€"åù#­G„)î(44Q‡«¢SÜ‘İƒ!ö&éaì9>ÀÄ¹c·Â‹lÀG¾ıØ“ÄÑgSM¯×£¾b*[¯6¢Cã¹ç¶ÙSÚy·Ï¬ŸŸ]<?»r~nÙüŒšùÉ‚™}`:dë¡wÅÕ7ïŠu*„ŞPÑağ÷6/³¤®§ºäİš9íÉË‚¢QVG©\6¯R1»*h¥ğRáu1ˆÒy¬H•–Ì‡(údêğòÃbåÉC…Î"DAÙ.+=EUU ‹³w<=8˜[èPY™Hh„¯S¿d¡*·,ªnqĞg±
’2©2«­Œ—KYdÜ-)øUZÖ»d‹Ëş¯xz3ö?óÄæŞ8âFiDm.a§r!ÄÂgpIÜ-ÁÅb‰î£¢¡ò>xÓly	u©Bÿõ¯urØm·zß±ğøğ¢%¤`÷Èx ™‚°„AöÒÄ	Ç8´0„sš_Ù(Ï;ğÅ/­Ãß†a·İT]1:‹`â9áõÄE´÷¡á;09›×¡§qA¨ùûÚuJQÚ‡Cè·ÎZ'¬Íc¡]‡æ+3dıˆB0ßï­îy{Ğ,–Š‚ºüŠsS±´+f¡¼Â+ÌGU”`nX®4ı&0‹.ÙâEÏâq96HİÁŠ	qú«¾)¨ïì‘Û“j™ëÛw¸=¨íÀÎÆz¬ö±Oåuqjµ˜
V*°oê	8W7_OƒsåDøz
¾qğÑ^Ô1D½h”ÇšÅÉËüÀB|.£»™yJ\Ç‹‚§3Ìµ»øñß*B±6û±œG”¯À¬æØTx¾BRœbu
"ÜX³œ0ıf$d^Nbæ!½iÔ×ÄOòa83,u½û\<ÜéÉ’¹?ÃÇ{@w`è:mR¢…ZÀ}çˆjF$Œ5Wå?ÒWÎèr“÷—W‚p|§rW†`•`Óİ<zJâé=¨1PIÎRÆ`/Â=úöçïU‚ïm¯é=ÌÛ+nTéFƒöÙïí³ÑÙy¯×é7U¥XŠ–šâV´bá†£T„ì4T[zÆ‘GãSiù?Ê)º©•eéFéW–n|İè*á¤Õéåİ)º3óTCw±&æ?j¿u†í“¦Z©H_R1©¦,ÖÔùNN§se+rtíÏqs±‡;!<av(q°\À,"‚¥WH;|§ô´[óš¿äóùÎââ¼	G§o{—¯.ÚvÀ¼Kªu¥[¤ÅûUB§ÿ3¯•¨4Ì$é9­¾„ï‘†Ìø .‘»Wş= úØ†øŠûHŞT¹rY~=H=>QÑ!:mCcSÚ^—<Q©Ç"i¸^w‘Ûå<?É_yˆ—óáßµóå•e¥'lnònÓëğ—G¢*äIÀ—Ë7Êq/}óÛ|ôĞ”Ãx¤Ïi-æXÉÇí_>Å¡ò9ä§¸â)ÑwrkË÷ÖZ|øy¯[ŸóşóD»aTZ}İ÷Ÿ?mo/|ÿ[ß­åßÖÕûÏoÑ’7{©÷Uİu•ÂÏ2^\…¦eäFU.>şñÇŠ¯y@ı*Üm¹<ï‡J÷ñI¨X'†zõ]‡èºƒ‰'ºÄ¡aÊcñXG‚M•µUû2ï¿³rıì¿QÛÚÎÙ£ÑØ]Ùÿ7yÿ™èkL‚aŒÕÉ’ôûa:Ù®Àœ²lÏT&9´{3ƒ)ë˜-ÒÙ }|ÒîaÕ:éwÛLˆ°Å£½ó“‘„ğG
ŠÉ¯¤0;¥˜è¯ølàïÛ‹Ë²ò hÈr÷_~`"³¯Ä-Ğ‚è>‡ß[ñ#;DÁ’ƒÉ‘¨ÜbŠ£KRé^[tïD‘L<4¼{Ìôxôœ|o\lôolv™‘’JÆ§¾‚Jí¨½ö[µ¼ŸÇî9ÈÓ›şmªh†A½%õ×óãöhñÕAç¸×ê
ts²€nÚJAàp[/¥Ç©?bqå„¦°~hù¬Tû,r+³!L'3âøßØr°&Ü@áĞ5ª Êû.rÚsÉâ„ôâ!£ZÔÍ€©ÿ0Ûrq&‘jÔ?v<®h&§‚^gT{^¾¤÷µ$lÔ#coO§Û°×¯A}‹œ¦rc nƒ0ëÆ^“şáp8¹µ/°ä‚pŠ”ê%s¿s¿Ç¹sÛÅN1½˜¿ tñş’^¡‰Dä6Érªœ›…BÔùò%ÿÑ?’ùÄ‚;¢|¥ügN®oH?m—â­”ç¡ã$Ëåæ¢r¹,C7İœÎC>£{ÎR¼+®âG<_\Ëó´{®ˆşÂÕ4êª$„ñ*/3A‘Ô¾r@oL¥zÌ_†X÷+ˆ&ÈÂÒè»$!õgPÄ3:UÑ'¥x©˜Iµ?èŒÆğ‚}ĞQH‰2:ŒİÕ»‰F'–9µE’BÏ&Ûš­R±U[µU[µU[µU[µU[µU[µU[µU[µU[µU[µU[µï¬ı¡»Ò8 P  