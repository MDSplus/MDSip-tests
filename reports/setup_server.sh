#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3795077729"
MD5="6cc0115dc2fdf76a7d203d7a9357ba5d"
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
	echo Date of packaging: Thu Mar 17 12:18:43 CET 2016
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
‹ “’êVíksGR_Ù_ÑYqÈ	dÙW’Ñ…HX¡‚%Pœœ¬¢–İA¬µìîíCÈü÷ë™}
ì³_S‰ÅÎt÷Ìô»g¦º¹öìmÛÛú[{»³•şµµZıÍÛúN­V¯o¯mÕ¶^¿©¯ÁÎÚ_ĞB?Ğ<€5Í6<¦-†{lüÿ´U7}„nÕŸü]ò¯o¿İy““½ööÍl­äÿìmı‡Í‘ioúEYvkàØÀ<Ïñ|5*LQú§íŞ Û<n5Š¥‘æ3[›2P‹[jYÛ§8f˜^jHa·®ã0hµÃ_NúƒFñ>õµÛ°]³&ÌrÀ½“Ó0}í6ş‰Ê’‡ë÷NN:	 ÿÜmlSwsjø¦;Wû½ÎY_¬ó>õ…À¡ïmò…Šk…şŒÀÛ½,àŒó‰U:‡ÃNûçÓæéÃ^sğKĞ2G»Åû':<0LE9l7;'GÃÔ,çRQ×3í`8a–[*Ã½¢k¼{­“÷Ê™¯]²](&RsÇLÇö/à\w¦STÕEÑäPôY-şœ|®Th–2Dí¥LL¨[tÅĞ.BûhÒŸy×Ì.—ÀƒĞg”6ÖB+à‚+Ç4|¤á»c•34¨Pˆ‚8Ãn; C´„RN°	Ñk$Šk9>“dı‰s¾î™.wBOgò+Â‰şJå9TÉ‘› ÓD—Ü½Ï|ßš6ŒGÁ‘S¦}A‹±dFÇ…üŒØ5Bİbš…fS7¸CY²%b2Ó‘Ãw
©Çú:¸šç3Ğ§ıB˜çï*7Óbp~]S¡Ñ€Ê\\ÀN4-èèÄ¸¯%n‰z=ŠZ¢èAÈ--ÜÛ{8kZ"rïæ€„[F^QxœƒŞğC»{xòaØoÿ»ÕØŞŞÙyız»ş8æaëç³£nà…ìüâ•NÌñ—1 ¶S¥P(d\j}ù,Pÿ¢y*å¯\ôcéÕ—LµQşßi1_ÓÃ±1¤™c8‡â:T¬ j@*f’è/Ó'¨m[w<²•”QTáõ](5Œİ1ê¾2Õ¹«­ªJZs¡¦ŒÑÁc‡6‡ ÕºZ0á®Á¦Wäø*.dÙlÙØ&Å‰eã^È÷#uÜåÛ?Ÿ¹1g&	é³Ë)zŞ¡oşÉ…u3,JÀxlà1ûqP„Ò¦AMÂËÅT¸ŞxfÀ8 ŒÉ•Mµ+r·èˆ)Ê™6è!
˜ÂLì‰¥Ú¨CúâT7“or™ÔÖaóÛ5A-#Dûzjßlm)Í¥õIµe×š«2~ó´¦İ›e”‘¼öL1@.ïa.by•2@*=töh2öVQÛá…Yfñuj<‡uMƒd&@ùä¼ã H[`†úmVÁœ•`ï“WL°sV|v8x°âÙ³jÆafdtïoÖºßÛİÖàpxpÒ}ßP™úÊ}ì^‘ÅÃàÎ}Jğ¾İiÍó˜2yùVUºĞ˜–cıP×1±JÓ¢RzíÃ<èX3­ĞcyP’1ÑÄŒS¦ªº›Z´aúÚÈÊ ÙI:åzNàè˜¥%£„GUG¿B‹K6İÎ2†¸ÑÌ ÇŒyİõó¬ªQA*ê¡P¦ÙÈ„ä¬Ûi·­„.ó†2«^ô@4¨Ÿ†[Ú¥Ÿ…ùµÕê5;íßZĞ=9lušà_¬¤>œ6{qUC†—£]¼?ë·NgJG‡üXÚºv¦mR*¡¡è#‡?Ÿ(w^s±¥·˜À)û†„¬;nôXyÙÆ€Ğ¥} Eb˜’õîØ6xñ²Z†~ûîñÿ¥Š¶¾DÓBÃMÆç¨šq‰iP1GÕî˜ŸŒ/“µD’ÉZ•èú—‹4‡²L´äå¿T´ë0STE%ğã>:±uPi-“4FMLQÉúT óãÎL8)bÄæå°ÜâiY O4›òÏÀgÖ˜\¸Ã>ÍEñbi¥!í„ ”U.ç<ÇíM;Õ}2Ï›Rô=M§Ì»ÿ	&Ò€…3şEÍ¥¶ªz`ajaa:¢Y·Bzt®¥é”‰i˜¤Åh¤é´ø»4m‡‘ˆ3æ]@şpBNÌ`ö]´\Fùy`ê¡¥yiIæABü°d¦ì<	¾U@~ê˜À’z=gÊ¡Ç¦ç‡3S3m±'”,çušvˆ®4ÄV
‡“ER¤Nh(eÃ	¡ëÛ4d?yôµS3€H y— ibyóeÌDÜ ®À0<âÉ‘ôÀ§#dL†¤ˆái•÷"tY‹‹
â‰î$}Íò>	¡_±»Ç3à¸ÙN†“ƒfn&&ß×m‚"µãg‚’ÁRß¹ÑK]õiXÀˆ…‰Eøw~À¦B•Úc¾†Íæ'L˜6!…QDÖÀ…¢!Ãì
êı5Ø%r,Ú	ÇF{AZ6JQ(1²-(aoÎùÚ\¦›¸˜h³ıVç}•Û0	O}~úŒIhRœº|µşIŒæ[Æ<ïM²g*¤ÏIÚ®cAR…CA#â4MË‚£#¸ª¥æ•Òs
ÑÎ5_œæ	oáLQ§&ìElœÑî¤Éro"wù©€Ê!6S!l¢näUĞäq['P¤<¤õˆ0Å…†&êpU”aŠ;²;0ÄŞ$=,ı Ç˜87ìZx‘øÌ·{ÒÃ¡8÷l¨ÉÉõztÀWLeëñ½Ftb<÷Ğ6{D;ïÔö‰õó“‹ç'WÎO-›ŸP3?Z0³[¦C¶úX¬Q}ó±X§Bècq*:lÁş>ş~ÍË,é€ë©.yq fN;Dò² h”ÕÑ}*×ŸÍ«”DÌ®
Z)¼Tx]Œ'¢t+R¥%ó!Š>™:¼¼]¡<zH£ĞY„(è¢3Ûe¥§¨*£
tqÖñ‘ç±ûûs*+	-‚ãuê·,Tå–EÕ-ºã,V¡³AR&Ufµ•ñri#‹Lƒ{¢%¿JËú˜lcqÙÿŒ§7ıÁIï+Olş¢ÓG\'‰£%ìTÎ…X8à.ˆ»%¸¢R,ÑeT4TŞoš-/¡.Uè¢ş\‡ V³û_ğ/Zâ÷@È4b÷À| ƒ°…~öÚÄÇ8´0ˆsªÏlGgmøÍâçæÁ¯ƒö Ój¨€ÎİE0ñœğrâ†"ŞûP¾ğ˜ŒÍËĞÓ¸(Ôüuí:%)­ƒôš§Íã>Vç±Ø.Csˆµ²~HA˜ğ·fç¬ÕoKÅ{A~Å¹ªXÚˆY(¯p„©Š,ĞËHÓ¯3°èší>^ô,—cıÔ-¬˜§°î›‚úÑîó¹=y¤–¹ÀıˆÛƒÚìla´çÈjûwU^× VP‹©p¥Bû¶ €suğõ48WN„¯§à·÷_ úş‹:©ÛeÅqƒFñ_òz?°ß‚‹èvfŞ×ñâ½àéóEíæ
~¼ç÷ŠP¬Í~,çå£G0ë„96±§XßAŸÂ7–Ä0'L¿ÊC™™“˜yDõ5ğ“¼ÎKïw{c²dîÇğùó.Ğ-:O›Th¡pï9¤ª	cÕUùô–3ºŞäıeÄ• Çéc†Ü•AX%Øt7Ÿ’xzjT’³”1Ü‹€Şıé{•¡à{ÛkzóöŠUÚıa¿uú[ëtxzÖí¶»GU)–¢¥¦¸­X¸á(¡#;Uçš^qdÀÑøTZ¾€ÇrŠnjeYºQ–¥›ŸC7ºL8n¶»ywEŠ.Í<ÕÆà]¬‰ù[ï‡íAë¸¡V*Ò—TLª*‹5u¾“ÓédÙŠ]ëö)n.öpÇd€ÇÌ%–˜ED°ø
i‡•®vm^Òñ—| #_ZœŸõ.àüğäC÷âÕyË˜wAÕ®t‹´x¿Jèôæ±‡™4ı<§Õà=ĞÄ%r÷Ê¡D»->âF’7U.†\–A÷SÏOÔ~tKˆNÛĞØ”¶Ã%FÔ~ê¹Hn×]ävùÄOòwbÁå|xã·í|yeYë	›Ûƒ¼u\	ëğ·G¢.¤Şè#ër9ğF9î¥o~Ÿšrô9­ÅÜ+ybâÀıÛ§8T@‡üW<&úNîmùŞÑZ‹÷?íÖqëóŞkWŒª«ç}ÿùæõë…ïë8–ÿY¯¯Şş-yÖ°›zòPÕ]W)ü$Æ(4-#7ªÒpñşà÷ßgP|Ç#êOPiç.Ìå‘?T:ŸHBÅ:6ü“Ñ'ôşëö'è?†)~L•µU{Æ÷ßY¹şö¿]ÛÊÛÿöv}õşû¯yÿ™è;Ì‚aŒÕÉ¾’ôûa:Ù®Àœ²lÏT&9´;3ƒ)ë˜.ÒµY¿utÜêb
Õ<îuZ}Ìˆ°Å£İ³ã¡„èów
ŠÉo¥0=¥˜‚è¯ø¥làïëó‹²r¯hÈr÷€ß`&³§ÄEĞ‚èJ‡_]ğ#;DÑ’^„É‘¨\c£KRé^[tïD‘L¼5¼;Lôxôœ|wwà1ıÛ ›İ@f¤¤’ñ©¯ R{j·õA-ïå±»òtÃ¦@„*ûšaPoIıåì¨5ÜB|µß>ê6;İÀ¤, Dƒ¶R8ÜÖKéqêÆY\9¡££)¬Z>+Õ¾ŠœÀÊlóÉÌ†8ş7¶,
7P8t“*ˆò¾óœö\ğ…8!=zˆÄ(…uóS`êÌ6¤œ£AÜC I¤õ+šÉ©àŸw•Ä—/é‰-	õÈØİÕéBìİ;P? §©Şè‹!L»±×¤8Nní	,¹ œ"¥zÉÜŸÄÜŸpîÜv±SL/æ/º GAh"¹M²œ*çf¡u¾|É¿gôäD~±àéÑÁ_)ÿ™“ë{’Å›×¥x+åyè8É2d¹†¹¨\.ËcÁÍG7§óOéª³ïŠ+„øÏ—#×ô<í+¢¿p5ÛuUÂx•—™ Hj_Ù§g¦R=æ/C¬ûD
daiô]’ú3(â«è“R¼TÌ²Z·:ã•1¼`·:ª)QF‡±»z3ÑèÈ2§¶HÒcAèÙd[³U~¶j«¶j«¶j«¶j«¶j«¶j«¶j«¶j«¶j«¶j«¶j«öµÿÖ}Ä P  