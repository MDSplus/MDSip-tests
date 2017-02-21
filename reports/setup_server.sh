#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1741034548"
MD5="c205576ec0ba0399d4d82359b2d76170"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4122"
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
	echo Date of packaging: Tue Feb 21 10:57:10 CET 2017
	echo Built with Makeself version 2.2.0 on linux-gnu
	echo Build command was: "/bin/sh \\
    \"--header\" \\
    \"/home/andrea/devel/rfx/tests/mdsip-tests-build/../mdsip-tests/reports/setup_server/makeself-header.sh\" \\
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
‹ ö¬XíksÛ62_Å_±¥t©äD²%ÛÉùªÚJª©,k,¹iÏöhh²S$?êè¿ß. >õpÒÖmoN˜k,»‹öàj›/½ma{»»Këow·Ò£ö¢¾½µ»`ÛoŞ¼Øªoí¼Ùy»/ş„úæ¼ĞlÃcÚr¸§ÆÿG[mÓgAèÖüÉ_%ÿÆÎ[”yVşÆVãl­åÿì­øÍæ•ioúE)»7pl`çx¾‚šU¦(ƒÃÓNØk·›¥ò•æ3[›2PK[jE:§8f˜^jHa÷®ã0l~hG?œ†ÍÒcêk¯i9ºfM?˜å€û'§)`úÚkş•%7èŸœt@ş¹×Ü¦îæÔğMw0"®úİ³àó1õ…À¡ïmrFÅµBFà~pÆ÷‰xèºïO[§¿Œú­áyxË¼Ú+=æ€â èB¬À0å¨Óê|h¦f9×Š¢¸i£	³Ür]àİ;hŸ¼WÎ|íšíA)‘T«pî¸éØş%œëÎtŠº{©( šŠ>«¢ÅŸ“ÏÕ*MT¨]£Óê]1´‹Ğ´œš”ÆgŞ-ó€¯3pàŠAè3Êk¡pIVb>Òğ]Ç±*Ô¨QDÁa·€¡ZB)'é„è-E®ŸI²şÄ¹_÷L‰;¡§3ùáDååw¨š#¿@¦‰.¹zŸù>nt~oÚ,0Ç2íëZŒ%3:.ägÄ®ÅêÓì,4›ºÁÊ’Å(Ñ&3wø!B½M€EK
IãŠBÚ‡–U,‚«y>}jĞ/´ÿ€yşr71-ççèê*4›Pİ€ËKØÃ‰æ‰7c¾ã–¨âÜPÔ»X
B>méàşşü¬iÍYŠÈ]£n)¹Tá®û£ŞÑÉÇÑ óïvs{{wwgg»ñ4æQûû³ÜÀÙürN'æøë6 ¶i¥P(düqcõ,Ğøªyª•ßÈôâ›¯™j£òûi1_ÓÃ±1šc8‡RªV u •F“Jô—éÔ­;ÙUÊ(jp†ú.”Æ‡ÆŞußG™êÜ-×T%­¹PWÆhkØÆ¡Í!HõF®Lx$@°é9ÉªÙ(8[5¶IaeÕ¸òõH$×:â¾‚ÏÜ\0“„ôÙõ½ôÈ7eOÂºŒH%`|là1ûiP„Ò¦OAMÂëå*Ü ï<3`ÆäÊ¦Ú¹ft„MôL!)í?Š	ÔG}ùrAO
 ¶™ W¥V„Í?®	jÙ#Úo§ö‡ñ–RnâOj6»Õ¬XÛñ[Ÿ0ıf$x¡‚Ú(Êj¸9~ƒaä1Ğİh`¦Âel—<ÅêôgM'—†=SŒ3ËÁX ‹¤¢F¹©Õ> i8˜3ì­Q@|©Df_úF] ‡LqX×4H!(Ÿ"CiñÌ 0Æ œ][hÏµ6$½€gìıâµì‚µ®Má&¶Pñ\ÁhĞ>ı©}::=ëõ:½3UXÆóÙ&ÌÈXÇ_l?wzíáÑèğ¤÷¾©*2éõ•G¥€’î\"Ğ„÷n.8|™'‹Ô’D+¨8öÈu“Ç4ªÏ ß9ŠaÆši…ËÃHhÃLL§e®»Ä aúÚ••·¥àzNàè˜t&İ„PğıM=YRS:r¥p§™AnDIwıüÒët€!³@U³qMÉØY¯Û9îÛ¸"õMV FçvUŒøàØÒ®ıìàív¿ÕíüÔ†ŞÉQ»Ûúÿ¢sÿxÚê+J/Ges†š=CF/˜LÛ0nLÚWça¤pùÆì”¿„÷c‹ñ¥?X¤9<Ï‡Cî¬n×XÚ†’Ğ¥U Ù`@”U‹îØ6ş¼ˆxYõ@W}øŸl‹¥˜¤øs
n2¾@qŒkL¸ˆúóÀüd|•À¨U‚L˜}Z 	ã_.ØÎJ“3ÿza¦¨Š8÷àg3ô7ERÙ/“47ML‰ùúTœó³¾?˜à'RĞˆÍKu¹Ì;Ó²Ğãk6å»Ï¬1y[‡£š‹BÆRNCÚ	1$@)²&\Îx%2èšvªú~e6¥¤ïi:eÚØ…øÿHà0q,êñ/ê/}Ä°5…”ô‹~Tnœ‹æ+ÊÉu+4P­¯Àµ42?“Âô˜¿b×¦]EpÆ¼ËB3¨Á/NÈ‰Ì~ˆVìhT¦Zš—¶”d$¤aÌ_>SvÃ„_*à~ê˜0“’=gÊ¡Ç¦ç‡o¦fÚbM(Y¾3ÔiÚ!úÌX)NI‘.8¡m ”=Œ„®GÛ¦áö“?@ß:5éˆ’w	’&öq¯ã}A3ˆ†G;Dç‡$=°Ãé	2&CRÄ€´ˆÊ{º‚[‹LñD’¾fùŸ„ĞoØÃãpÜê†'£îÉa«w“¯‹ë6A‘ÚñL¹ÁRß¹éK]õiXÀÆşƒ°©P¥Î˜óp§Ùüô3Ü_a‘5p¡h¸avõşìw,Z	ÇF{AZ6JQ(1nZP²½9#ä¼¹L7‘™h±ƒv÷}Û0	O™~úüIhRœºœ[ÿÎ¤æKÆ„î“L²g*¤ÏIÚ®cTƒ#A#Úiš4–G—©]zŞX)=Ç¡p­\óÅI£ğÎõxj"a±½ˆ3šÁƒ4YîMäê#?PùÅÆc*¼MÔMƒ¼
š<.kâ„Š”§zÄVÜQhh¢WE¬¸#{ C¬MÒÃ‚Ürû çİ
/²ŸùòcOz4Ç²M59f/F‡¥TZ_Â¬<ZÎÖŒ«Ï–Ÿv/9}Îbç«ı|ÀP–ÖúK!ç*ıÕ©:)`ªÊ_“ÔøsXWÑ216(†ª¾?¹P£šŠİ3=UWa}æO qp€Ğ;›ˆQ“÷#Ì¢£¿4¥WuB"ÒX~]”¶¡ªÃ¤ğe4X@k#5{Ü#rª%%1ÿVyÅt%Sª\˜]¨*æóåšH)j‚ì<‰T°š„È&–ˆŸ“XÆ/§¯î—C(Ob-¯$‹² Å_1-êä¨¦^‘_ñ¼ƒƒEìòB9‘ş2¡¼ò~Ò»(Ä•Cœ¹Ña
Úê³*sıêxµ†áNš÷Ì+ÎDTâş"Yíê“‘ßwzğ,ÇƒáIÿ7¥ıIÇj¸9‘4š+D¡œ‘rÀ\’dÊpCñ¸T¦{Çh¨²Ş4[ÏŸ÷VÌ 5õwÏ0{&!vÛ­ŞßXˆüBO‚2	Tl7g€¸MÒœ„1²—| N{Æ¡…i§I†õŒgÎÎ:ğ74ï[‡?;Ãn»©R:„'˜xNx=qC‘ùP…ğ?˜ğÍëĞÓ¸ Ôüı|‘Ò¾öáú­ÓÖñ Š‰Ğ®C”…[?¢œ„‹ï§V÷¬=h–Ê¥GA£KÕ¹©ZÚÃP:¯0ÇWQ‚º%»Òô›À,º(}Œ™Åãrlºsâô1VÒSP/ì‘Ë“ç‰™ëú\ÔwawS¬ö±OåÇu¨ÔR*.ªPÀ¾-h$à\İ|#Î•á)øíƒ—ˆ~ğ²ÑğåvEqÜ Yú—¼`ÃÌÍ¶’Ğ³è‰H™ëxéQìé3píî¾}ä7ÃPªÏ¾­äå›‘'0„‰Á†§7$Å)VÌ0 @Ä%1ËˆÄÌ£T*ˆ6ñ“üÎ+]ğ¾HMÉñÉ’¹O“ëºÇD÷i“*-
Ì2¢:	c[ıô—3º æıä6%Ç'dúBìfÈU‚Îğ(,'H¯#†‚²œ©‚YDåTbõôze@ø;®7½Eë¥Û™¹£©*¥rÄn.}Jò³(­¡#QUè–ïdÀÑUZ‚€ÇJŠn.uMèF_–n|]UFÓãV§—w[¤ğ"Ü,ÌµĞBëbş£öûQgØ>nªÕªô)U“êõR]]ììt:œ·"‡×¾ÿw{ºc2Äcf‡	Kf¬KCZá…ÒÓnÍk:X”Ïäûšó³ş%œ|ì]¾>oÛó.éAºGbŞ¯:ıWz¤rˆVQÍ)
Îsj}		Ò|Ê‘?îcù/tƒèh·ÅÇP\,ó¦JNÈoùô õâHD7¹è¹Mim1\òNH¤^¥á–¸Şe¾—¿ÔIœ%®#®äc4ÁÙ«ÈêP˜Ü>ä})æ0ÖáÏÍDuË3€~—oTâ^úæÏ2ĞMS"ã‘2§U˜»a%OLÜfüñy„üx\¼û›Ü­óµ£©–¿ÛkÌx­¤ßÿk7Œ
´ç}ÿûfggéûïÆÛzşıo½±³~ÿûg´äÙÉ^êÕJMw]¥ğŒW¡i¹Q•†K‡?ÿ<ƒÒ;
¦¥ï ÚÉ=6·(PíÎ¿…ªulø'WŸĞoø‡®;˜x¢Kü¦üá1u$ØTy±nÌûÿ¬\ÿûßŞŞ~›³ÿíí­µıÿ)ïÿ#}‡é¯#Œ±69P’~?0L'Û˜S–í™jÁ$‡öàoæáb0¥ˆy"İDÚÛ=LŸZÇın{€Ùµx¸wv<’ şºC1ùM&¦ôóı5¿(…ü}{~Y¡§'4d9{Èï”0ÙW
âòˆ#º&ã†ø‘¢PI¯úäHTn1ÁÑ%©t¯-ºw£P&Ş‹Ş¦Í…º<úÿìí‘ƒ€şm‚Íî 3RVÉúÔ×P­¿µ×ş¨VöóØ=7uÃ¦›@„ªšaPoYıáìC{´…øê ó¡×êz”ÿ-!R_FetÚd)
æv]ï,!œê¬ ÆI9EıÑø‹¯$tt´µ€õCËgåúo"'°2†ÉjfÃRÛ”İ“ ßNÿ7¶¬O7PSèª\pÀûÎsº|É¹vBzÛé”Ô ¨›kSÿk`¶!•.ÄšDâ;<v<®õ&§‚Şeì{^½¢7Û¤y¨ÔÆŞN7ïŞúÅBeÏ@\Ùa€½&ıÃáprk_`I†pŠ”$ssÂ¹sËÅN1½˜¿ 6èüÓ%½äB{Èm’×øn
Qç«Wü{FÿÈÈsKùˆ^•lpNùÏœ¼'Y¼Ù)ÇK©,BÇIV!K¢r¹¬B·İœ.B>¥»ìr¼*®âG<_\Ëó´®ˆşRn¶ª,„ñ:/3A‘t¿z@ï–¥z›ö±v¿˜Áıkˆ¦}-LGP6Jİe	8×áñ”÷Œ{ôI9æ“¼ö½Îxµ/Ù½:E•Qhì®İM4:NÍé0’ôXz6Úl%®Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûÿoû/cò%ë P  