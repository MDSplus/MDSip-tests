#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1158384765"
MD5="172f59d2ce69a312f937174398fe3e14"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3964"
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
	echo Date of packaging: Thu Mar 17 15:32:12 CET 2016
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
‹ ì¿êVíksGR_Ù_ÑYqÈ	$ÅW’Ñ…HX¡‚%Pœœ¬¢–İA¬µìîíCÈü÷ë™}
ìØ‰¯©‹ÅÎt÷Ìô»gæª›k_½ma{½»Kk¯w·Ò£¶V«ÿğº¾»ıúõîÎÚVmkwk{v×ş‚úæ¬i¶á1m1ÜSãÿ£­ºé³ t«şäï’}g«^ÏÉ¿^ßª¯ÁÖJş_½­·92íM¢(ëÀîÌ ˜ç9¯ f@…)Jÿğ¬İt›'­F±4Ò|fkSjqK-Ë±áQûÇÓK)ìÎu¼ Í³ãÖ`øóiĞ(>¤¾ö–£kÖÄñƒY¸wz–¦¯½Æ?QYòpıŞéi'äŸ{Í`ênNßt‡#âÊÉQ¿×9ï‹u>¤¾8ô½M¾Bq­ĞŸx»—œq>q¢JçhØiÿtÖ<û}Øk~ÎZæh¯øâDç‚†©(Gífçô¸a˜šå\)Šâz¦'ÌrKexPt-€7o uúV9÷µ+¶ÅD*P©À…ã¦cû—p¡;Ó)jë¥¢€hr(ú¬ˆN>V*4Q¢v…‚&¦Ô-ºbh¡I	4©‰Ï¼æMàÀˆAè3Jk¡pÙ•c>Òğ]Ç±ÊÔ¨CDÁa·€¡ZB)'Û„èÅ5ŒŸI²şÄ¹_÷L‰;¡§3ùáD%ÇòªäÀÈSi¢KîŞg¾ŒÀïL›Æ“àÈ)Ó¾Š ÅX2£ãB~Fìš?¡n1ÍÎB³©Ü£,YŒ1™éÈá{…4
íc}\ÍóèSƒ~¡Ìó÷”Û‰i1¸¸@›®©Ğh@e./a'štt	bÜŒ×·D½E-Ñõ… ä™îï?5­¹ƒs@Â-#Ç(œÎaoø®İ=:}7ì·ÿİjloïîîìl×ŸÆ<jıt~œÁ¼=‚_¼Ò‰9ş4Ävª
…ŒW­/ŸêŸ4O¥ü™‹a8½ş”©6Êó5]1£š9†(®CÅ
 ¤Òh&‰ş2}â€Ú¶uÇ#[IEÎQß…RÃØñĞ€Ñ#£îû(S»Úªª¤5jÊ}<¶qhsR½¡«îİlzM¯âB6–Í–mR¨X6î…|?RÉ]¹ıó™sf’>»š¢çúæìIX—1É¢ŒçÁ³ŸE(múÔ$¼Z¼@…à­gŒÂ˜\ÙT»&w‹˜¢œiƒ¢€)ÌÄ>‘Xª]3:ä¨/^Àã ŸğPİLPÈ«R[‡Í/×µlíó©}±µ¥”›Ö'5›İhV¬íøÍ“Ÿvo–ÑWrLØ3Åh¹ìˆº÷UÊ}¨ô Ğ]8x¤ìØ[Eƒ€Jd¼ÅïÔ9phÖ5« å3ã$mê—YqhsV‚½Ï^1ÁÎYñùÑàÑŠg_Uë0T3#£{³ÖıÖî¶GÃÃÓîÛ†ªÈ4ÑWbŒ,÷î£hÛ€·íNkS•ù¥HÉªÒËÆ´{è‡º¹Wš4ĞkåAÇši…Ëƒ’”ˆ‰&&¥2›ÕİÔ¢Ó×FVÍN2.×sGÇD.%ô8ğ:ú5Z\²é†ô§1Ä­f9f¤Èë®ŸgUJuŒcQE;ÍF&$ çİNû¤=h%,p™7”‰÷b G¢@ı4ÌØÒ®ü,Ì/­V¯ÙiÿÚ‚îéQ«Óüÿ¢7~wÖìÅ…!^vñá¼ß:›)@òciëNØ™v´9H©4\„†R C.ş|¢ÜyÍÅ–Şb^Œ§Eœ²î¹Ñcqf;B—ö‰‘L–ºcÛL8âuÄËjúì{Àÿ–*ÚúM7Ÿ£jÆfJ	ÄU»g~2¾Lş	ÔI&k}R¢ëŸ.ÒÊ2Ñ’—ÿTÑ®ÃLQqàÀEúèÄÖa@Õ·ÌWĞ=6u0‹I$ëSÌ-8g0'L¤ˆ›WÌr‹·¦e>ÑlJQŸYcrá¯	5Å‹Õ—†´bH€²ZM¸8œ3ğK$½4íTô	üÁ<lJu:Ò÷4’cìBü$p˜kÖÖø5—>bØªBêyˆµ7ª5N„µëˆÒhİ
TèÑ=¸–¦S²¦a£‘¦ÓâGìÊ´mF"Î˜wYh Uøİ	91ƒÙ÷Ñ.p9¥ğ©‡–æ¥m$™	iğİ’™²ó&4øV	 ù©cKê=öœ)‡›pÎLÍ´ÅP²œ3ÔiÚ!ºÒX)NI‘.8¡m ”='„®GlÓıä	Ğ×NÍ@z"ä]‚¤‰}äuÌ”10Apƒ¸ÃğˆCtpGÒ;œH1’"†¤ETŞ"ˆĞd-.*ˆ'º—ô5Ëwø$„~ÍîoÏ€“fo88vN›¸˜|_\·	ŠÔŸJK}çF/uÕ§a#&áßû›
Ujùn5›BaÚ„üFYŠ†³+¨÷7h`WÈ±h'íiÙ(E¡ÄÈ"´ „½9#äks™nâb¢Íö[·UnÃ$<YúécD$¡iHqêòÕú·&1šoó¼[¬EÉœ©v<'i»5KˆÓ4i,àª–š7VJÏq(D;×|qà'¼…3E=šHX°±qF3¸—&Ë½‰Ü}ä§ª˜ØxLµ²‰ºiWA“ÇmMœ0@‘òü‘Ö#Âwš¨ÃUQ†)îÈîÁ{“ô°†öƒ`âÜ²áE6à#ß~ìI†ât´¡&çÛëÑ`1•­Ç·Ñ¹òÜ£İl™7ïl÷™%ö³ëëg×Ï­¬ŸQV?YS³;¦C¶z_¬Q}ó¾X§Bè}q*:lÁÁşŞáe–tÀõT—¼^P3""yYP4Êêè!•ëÏæUJ"fW­^*¼.ÆQ:©Ò’ùEŸL^Ş-†P<ÇQè¸BtÑ±î²ÒST•Qº8ëxÏóØƒƒ¹…••‰„Añ:õKªrË¢êgáq«Ğñ!)“*³ÚÊx¹´‘E¦Á=Ñ’‚_¥e½O¶±¸ìÿŠ§7ıÁiï3Olş¢ÓG\:‰£%ìT.„X8à.‰»%¸¦R,Ñ•U4TŞoš-/¡.UèOQÿZ‡ ‡V³ûß	/Z"A
ÖxŒÊ‘)Kègï…@œpŒCC8§ù•âø¼ß QüÔ<üeĞtZĞ£³&^MÜPD{*Ğ¾““±yz„š¿Ò]§¥u8€^ó¬yÒÇÚ<ÚUh±2CÖ)sñıÚìœ·úb©ø ¡Ë¯8×K1å0UQ‚º„iúu`İÃ=Ä‹Åãr¬Ÿº¦âô1V}SPßÛ}>"·'Ô27¼ïq{PÛ…İ-ŒõYíaÿÊëâÔ
j1¬T(`ßÔp®n¾çÊ‰ğõüöÁD?xQÇõb»¬8nĞ(şKŞßàâ[p]ßÌ{GPâ:^|<a¶¨İ^Ã÷üâŠµÙ÷å<¢|Xğf0Ç¦Âó’â«;èSáÆ’˜å„é×Cy„ ór3èM£¾~’Ã™a©ëİçâáNoL–Ìıá>~Üº&C×i“*-Ôî;‡T3"a¬¹*ÿ‘¾rF÷Ÿ¼¿Œ¸„ãã8}Ì»2«›îæÑSOïAJr–2{îÑ·?¯2|k{MïaŞ^q£J»?ì·Î~mÏÎ»İv÷¸¡*ÅR´Ô·¢7¥"t`§¡êÜĞK8ŸJËğøQNÑM­,K7J¿²tÓàsèFW	'Ív7ï®HÑE˜™§Úº‹51ÿQëí°=h4ÔJEú’ŠI5e±¦Îwr:+[‘£kİ=ÇÍÅî„ğ„Ù¡ÄAÂr³ˆ–^!íğ½ÒÕnÌ+:ü’/däSŒ‹óŞ%\¾ë^¾ºhÙó.©Ö•n‘ïW	şË<h¢Ò0“¤_ä´ú¼G2ãƒ¸Dî^ù/ô€èc·ÅÇ@\Yò¦ÊÅËò#è~ê}ŠÚîÑi›Òöb¸äU‰ÚO½'IÃ-ğº‹Ü.’øIşD,¸œoü:/¯,+=asûw£˜¾X‡?NU!Oj æ¸\¼Q{é›_ø£‡¦Æ#}Nk1÷ÀJ˜8nÿò)•Ï!?Å¯¾‘[[¾w´ÖâÃ{uÜúÚªıµêæ‰vÍ¨nşºïØÙYøş»şº–ÿ[ÛÙ^½ÿı+Zò`e/õŞ¥ª»®RøQ&£Ğ´ŒÜ¨JÃÅ‡Ãß~›AñÏ–~„J;÷B^æ@¥óø‰,T¬Ã?}À¸àºnâ‰.ñc`˜ò‡ÇX<Ö–`Ó•›úRöŸ•ëß`ÿÛµ­œıooï¼^Ùÿ_òş?2Ñ7Xá8Â«“%é÷Ãt²]9eÙ©Lrh÷şf.SÖ± Ñ~ëø¤ÕÅô¸yÒë´ú˜íb‹G»ç'C	Ñç/P“ß7béA?0½Ô_ñëZØÀß7—eåA)Ğå8î!¿ÙÂ,u_)ˆ+8 Ñe”0ÀìeBôPD@ÕàóW]’J÷Ú¢{7Šdâ¡iàİcaT( Ç£ÿ;ÁŞ¹0ØèßØì2#%•ŒO}•Ú+P»­wjy?İu§6ıÛ "T9ĞƒzKêÏçÇ­áâ«ıöq·Ùè&Ü]´•‚Àá¶^JS4şÄâÊ	M!`½ĞòY©öYäVfCX+d6Ä!ğcËÁ‚…Cwä‚(ï»ÈiÏ%_ˆÒs–HŒRhQ7?ß§şWÀlCÊ9Ä=šDªQÿØñ¸¢™œ
şy“QIìyù’ŞW“°QŒ½=®:ß¼õršjÉ¾¸êÃ’
{Mú‡ÃáäÖ¾À’Â)Rª—ÌıAÌıçÎm;Åôbş‚`ĞÅ‡Kzî…&‘Û$Ë©rn
QçË—ü{FÿHNäWîˆ“lğ•òŸ9¹¾%Yü°SŠ·R‡“,C–k˜‹Êå²9Ü|ts:ùŒ.±Kñ®¸Bˆñ|9rMÏÓî¹"úW³]çP%!ŒWy™	Š¤ö•zc,Õcş2Äº_A4¡@–Fß%	ñ¨?ƒ€"Ñ‘™>)ÅKÅLªu§3~ê/ØjDJ”Ñaì®ŞN4:Î©-’ôXz6ÙÖl•Š­Úª­Úª­Úª­Úª­Úª­Úª­Úª­Úª­Úª­Úª}ƒí¿äz38 P  