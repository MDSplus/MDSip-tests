#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="95774549"
MD5="2acc09da02919478f88a1bef55ddfe7e"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4584"
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
	echo Uncompressed size: 28 KB
	echo Compression: gzip
	echo Date of packaging: Tue May 23 10:12:14 CEST 2017
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
	echo OLDUSIZE=28
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
	MS_Printf "About to extract 28 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 28; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (28 KB)" >&2
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
‹ Şî#Yí\ysÛF²÷¿Ä§˜@\/)›”HZö–ljÃH´ÃZJb‰Rœ<IÅ!	W0€•ùİ_÷nñBb%~¯Ğµk3¿é9ú˜£gRßyñì´ônoÿ6Şíí&ÿ†ô¢Ñj4vß½}×j½}±ÛØ}ón÷Ù{ñÏ<Å%ä…bi.U–ãÖåÿ¥ú£ïÔÙìï’koïmVşÍ&¨Ù-äÿì´õÃÎX·vØL’¶½×=b[„º®í2	4ƒÔ¨$Ïzƒó“Îq·]®ŒF-Å¤D.ïÊÕ otÔ;ƒ<MwY½wl×#ç³OİóÑÏ§Ãóvù1ñµß6lU1f6óæğàô,Æ¯ıö¿@Y²¸áàô´ùç~{Ç3Scº3ò(2—†ƒşÅP´ó1ñ`Ÿ¹;¼!XÄ1|6GxoÎù8q¦aúG£~ï§³ÎÙo£Açüç,ŞĞÇûåÇ(ê @–ò4]’zşé§¶¦+†=•$ÉquËÍ¨áTªäQR|ø@º§¥¦Lé>)Ç2"µ¹´O·-vM.UÛ4Aw¯%‰
²ÂÏš èsöµVÃŠª$¤)¨7ÓÁd‘¡@cwb4*£î-u	ï§g“1%>£©ht¢ø†Ç%Yx0àÁÛ6ª)˜B@£ól—B²åMñ”˜SFÒ1Ó[`
mÛŒlÙÌ¾#Luu˜Û¾«Òà+,şF,;Bµı†GR$’‚Ş3Êt¿×-êiká0Rº5Ñ"/®ÑvH¶FHZ\¡jPÅJ£©éx K	™ª0ÂaÑ©¯²¨kB!1_’PûÀ²¶¶ˆ£¸ŒÕÔğØ¿G]¶/İÍtƒ’ËKğ™´Û¤¶M®¯É{¢Ùa=Dg"òõ¨İÅªø$+¤Ø.–BĞ§-Í|ÿşi­IÍYZ»F›¸¥0t©Â]FŸ{'G§ŸGÃŞÿtÛ-˜õŞ¼i5×—<êştñ)UÖs}ú¿¼¥3}’o "›–J¥RÊ7W×Bš¹ê©Uÿ`£Ç0ßä©j»úçyQ¦¨’f[0êrIÊ[¤fx¤AP¥Á¤bı¥êÌ&rÏRmí*aurú.”šLlŒ¼7è>™ªÜ-×e)©¹¤!MÀÖ€&¾Å¨z#Gñf|& ˜yƒN²æô,8_•·ƒÓÊª|×çı	t]ëˆû
^s{AM’Ñ©	^zÄôÿÒµX‡RØ‚´Í°K­õP@)æ:ÔÌŸ.i`äNîbv ç¡Ôœi#EÍƒçC»›¢©¦4r`›9°­X3ö6vº› kôwä*w›2×&F>¼®ÚÍå*á17'æÂ3æäÃß›ùğ“\x%ó1¸—|x/jÓ\xó.Ÿ°ìI¾ö;4'~’¯=Lõrâoóá=5/şKŞ~NuÎÙãû|=öìI.¼ªjùøÓ|Ö™Îr˜:z^|3çˆæÓ	Ófùz0É©t”Ù¹ğÖ8ßYN>'gè­|"vÕg˜Äww®îQ¾"Ü«™Êî=a§‡[~İ"ª+XËKoEEÑ/úòå‚ƒì©©ïÄEpÛˆ´Ev¾	né=µ ?Îí›µ-±zÇöKwz«Ñr¾ÕUoF¢í#X[ ßoü ûäGOuÂŒ¹L®£?Cêæ©¥<îÙ Å„4É2QO§&u<|c¤6 Àš<Ù@jwü/¥p_SşA^€ƒFq¬£k¨ÊkÀ­otÜ€§nq&:ìYS}ó5ï¹ú¬´R7îbôíâè|aß$¾!_(Ï¨®ÇŞp4ìıÒ=]œœôN>ÍeaÏgºMLYÇßl¿öNºçG£ÃÓ“mY
Nõ˜ô(•@2#ïÁyrÒÑ&{ı.¹Z°£ÅÙŠVp±­óU•2–ä‚ĞdĞ;Š0E7|—f1(0])U³¯26RxË–Jk{¶j‰d,Pb¶z¦w©ìT¥Ò¢{™>"'ÕaÙ®70`BR	úç]œô{Ç½ó.ôÈ}8ä>U‘;ä™C™²tæºİA§ßû¥KNNºıÎoğœûç³Î@’J>‹mX dsš=‡†Ø®÷43iÃ00I_ÅÂå¯…ØLPl	?îÇ—üÁ"Íá™äPLwÆ·k`*ñì˜LˆÁ±¬j[ş|Ê¥Õ\¤=ÂÿZ¬([ñæ…ñ5'Î_ 8ÚÔ½‰ôç²8•ÀcÔ*AÆ]/Ğ¸á›6Sf¥€Ñ™çğ™K²$;<ø4³EÎ1®,~ÀÜ\jÚ°$ŠåË0úÀƒC||XJ‚†Ò<tóN7ğøŠ…z°o7&èmm~Ú®8 dÇÕà3x¨×uz®mˆ#Âm¬ÖT<uFşK]› ÌÄğw!	Êÿ#ÆÙÔciğô?"l]B%=´M<™ƒŠ#2º¥>ì‰Éø8†¢âÊOEaTõ?¦S]L][Äğ$Ì N~³}ÎL£ÖCØh‚®ú†â&-%®)0ç/¯)]ÏaÌƒw0*¥*ùÄµMè.óx>˜Šn‰>dùÈ`¢nùà3}øa$Êp¶À
uÁö-¤ìÂl€ÅÕpØ~ôà[Mİü² ö"±bcÈ˜P ĞAh¦¹8B EéË7Ç(ÈˆJ¦à…\>Dè
-4Ê‹*zø+³y%Xü†>ÜÙ®F;ƒÑùé¨zØé“»™ÎûÅuQ¨v<Bp ïÜô]e˜-0¢a¢ìyÔªÔ›ğ6Ü)ïÁÊÆWEh\(
˜U½¿›Âˆ…=á¥Á^€—RJCoÆyÛªêĞ˜°³ÃnÿcÛ0
/8EgÉ D¡)ÀÑtxkÙÍ»º;Xd¢-Ø¦vT'j»
 :9<Â‘ÆJ#YğâÁÒ.Yo¤”®mãtö\a"”*¼…m‚›:0Ã¥¡Fİ{L–{“ ÷¡ŸòpûE'Œ,è ›z0yèÖÌö=)_êa{ÄdÅ…&jsU&+îÈˆ&úğ£÷:ó2ã@fö½^d›|åİ<éÑHÄÛr|`+Œ®–Ëòè–ÉÊØyzÏ¸:x¾8œ¿$¼.gd'ii0c)òI(c52ÈX
L„1–aâ Æ„”a\-;XÀØ;Îƒu7ÃÆ¡‹Í‘­‘æÆÈÛ‘Ó5Hia¸bãt°b-:ªX‹O*6@ÓèTb=:¢Xä@+9§‚ ½èT`b-:–X‹N%Ö¢S!‰õèI–¤Â oó “§Â› ¿äƒû¹6W?ïóô3€X‹N…Öó¦y¤™=¬…§› ›¹Æ0ôÓ!‡õ~6—j¥ÂkÑ©`Ãz´“Ça¥ëÅéªß^>xQ×ZäêêªÜÄ­¼ÌØìJvé=UÇ»¹¤ypÀñovx©zp•xÍ*SÂáÈUÔfüG‹ÔT²K2œ‚-ê’
&:®j“mÄaÏ’³zş-ó£Ü+¹ü˜8Çœ_É2!Î‘ÅYG]°}Ê"q4±š…8æXÂ \‘sËÚÀÏ¦M[#¯î—#¤µ×‡–qo'ãá…Ä?wÊ/ğÃÃş?üêÔÁÁ¢æòüX–!„2ğÀóÄ¶‚xˆ¸ì)nåë ½–ƒCÈÚdµ†ÁHêß2®ÖÈØú«¸·«C6.¬ñ,qáùéàÆøş¢xŸ-îlPí¢.…H9pN®Q2rƒå
Şø³ªï‰k¦°UòõëşŠMıÓ5ÌŸIˆ‡ınçä;"¿J-&‚

TûÄ a˜sÆ0L_¯&"5ñãAğDÃzÆ`ø§‹ùã§ÎáÎ{çın[Æsp8ŞÌµıéÌñÅá#52şGµ­‰>õ]…BÎ¾ŒØÂó¨îá9tÎ:ÇC²mêëà¤ú®Z¸ø~éô/ºÃv¹R~Œ`v©Ù75CS˜J‡şØÔ=$XÂûÉcE½ñtÏÀ+êQ£çQ~7L¼vBõhbƒ®ÈWÖçİ©‡WĞ=ÒØ#{»°tá…å¤ïË<Ò ’\NÌ‹2)AÚ.iÆp®nßLÂ¹r¾™À·^Bñƒ—M˜_¶ª’íxíò¿ƒ«Íğ«µİxêYô8§Âu¼ü(ÆtN¾åî†üó‘ßÉ'åÆüŸÕlÁàµÎš’M,	“_Ş MæÉ!NDÜXb³\0¡˜ù,•˜DÛğ‰~j&+]ğ{±\EÇ7AKæ>q‚®àrpŸªòÂ‰!# ctö÷À_Îñi OG·@xy,Œ_PºNä2¢Ó|*Hö#B‘JPS&f1+'VëûLßc“ıXÔ_¼6òd‰Ñ–¥r%lnfù¯ÏÂeÆjP¡[|8•‚ƒÊØ‡j‚oféóW|i¾Iø¾r0›wz'Y·…
/¦›…k-°Ğ†¨ÿ¨ûqÔ;ï·åZ-ğ)5	å†¼ØÙ©xkÀ^÷~wyºc4ÄcjùA`4`21!{x%(·ú#Áƒ³àeÓåÅàš\~>¹~}Ùµ<ê^c€#pØxVÇâøÿò#n‡ğQR›‚ËŒZ_“¸ĞÓ(Ï„öqËGÛçâÆ'9h	ú-¢‡‰·^ò0¼b[S¨‰}‹pñ-y˜x›•Ä-q½Ë|/#;KşPJ4¸šãøsŞ¼j°;&÷d})¬aÖæıÄî–¯lYàw9x»¥â7n2.*sR…¹–²ÌÄ5‹o¿ÎÁcŸÇíÅË½ïäÒï;˜jùñÇıæœ¯ ¥ïïı÷±rCq›ø¼ï¿ß¾y³ôıó]#ûş»Ñ*Şÿ%ßÊİO\ê­«#•~æ«±¯Z&WÆìòãá¯¿ÎIùNéåI­—¹‹\2!µşÓ·Ñ¤fkìtü¼;tœáÌIâÇ¹¦?\J£¼^ 3¥}ûOËõo°ÿV«õ.cÿ­Àûÿ+şû¡‰~€E¸-Œ±>;âtæiºNòt“¦SLÅ›eŠ=°,.‚I[°ZÅ‹ZÃî§ãî	,â:Çƒ~wk2¤(ûäâx@†üò«¤ó‹P°<Æ°
R_ó{dd~ß^^Wñf.f¶íò+7°˜z/•Äİ ‚-Â[DüÎä9|¤³pÂÆGANª{·°ÌRVÉTK$ï…S™x/ì¹°x/•ÀåáOb}Ùöğß6±èIåTd´>ù5©5^ù¤ûY®¾Ï–>±aP·-ü·MQí@Ñ4L­È?_|êv¡¼<ì}:éô±x¸
]Â¤±ŒËè¬;Ls*•4XazxûM£1ãDbA‚w&•d)Ló×t¾óQÁÖ<:ğF+?ÄN”J,™S–¦ô˜d€|L8;øßÄ°a—¼š‚7	ExÚeF—¯y«m¯ş†:hP˜Ì×1ı5¡–(]˜	ö” á‰ír­×9øó!eòê¾ÙGÍ¥Öö÷U¼öá‘?ƒXpó57š`©:şÃqP¹ñ^”
U$ì ®û‹¨ûÔé.$ŠêEı%1@—_®ñ¢;ØkÈnÍ¸ÎG³T
_½âßsü'‰l")á¥ÛmŞRş3£QoßT¢®T‡JVÚ°°(—ËªÂ‘à×ÍE…Ïğª_%êWñ#ª/Ã®ãºÊWD¶´5­&GU„0^ge&8¢î×ğYW Çºu¬Ü/nŒhıkVûZ˜à$l“+ğIzXg€¼çxè¤Î*Q»a‘×½W)?3 /é½
:…•RhH®ßÍ<ÔÍè0°t©ç»Ú¼X%TPATPATPATPATPATPATPATPATPATPAôÿ‹ş2ãió x  