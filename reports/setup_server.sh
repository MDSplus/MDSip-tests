#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1452419944"
MD5="8da94b5a7ff0f180763ea5f311dbadbf"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4607"
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
	echo Date of packaging: Tue May 23 11:52:42 CEST 2017
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
‹ j$Yí\ySÇ¶÷¿šOÑt}%l	$Ar[Ü( ;ª+@… NPªÑLK3[¦gX.ÖwçtÏ¶ILâ÷jN%Àtÿúôr–^N·ë;¯^œv~ØßÇßöw“¿CzÕh5İİVc¿ùj·±»··÷Šì¿úÈgâòJ±4—*ËqëòÿR}‡QÏwêlöwÉ¿õ}ãû½Œü›€“İBş/N[ßíŒuk‡Í$i‹Ğİ#¶E¨ëÚ.“@3HJÒğè¼7¸8íœtÛåÊXaÔRLJäò®\òFÇ½sÈÓt7‘%ÑÇv=rÑ9ÿØ½ı|6¼h—Ÿ_mÃVcf3oÎÎ`ü:hÿ”%‹ÎÎú1´w<ÓÙ15¦;#"séäx8è_E;Ÿ_ ö™»Ã‚EÃgs„÷iàœg¶¡<ê÷~:ïœÿ6t.~Îâ}|P~Ê€¢ ta)OÓ%é¸×éŸ}lkºbØSI’W·¼ÑŒN¥J$UñÈû÷¤{öAºdÊ”r,#R«‘+ÛñtÛb7äJµMt÷F’ˆ  +ü¬	Š>g_j5¬¨JBš‚x3LIÚ4v'F£Ò0êŞQ—ğ~z6Sâ3ª‘ŠF'Šox\’ÕˆÌ±m£šâ)4
90Ïv)$[ÑO‰9e$3½¦Ğ†±ÍhÀ–Íì{ÂTWw€¹í»*¾Â2áï`Ä²#TËÀĞox$E")è=£ŒÁ@‡ğİ¢¶#¥[Ó-òâm‡dk„¤ÅªU¬4šš÷²¤Q‘p©
#üú:!‹º&ó%	µ,kk‹8ŠË(QMÿû÷¨Ë¤û™nPruŞ !“v›Ô¶ÉÍyG4;¬‡¨àLD¾µ;¢XŸe…ÛÅRú´¥™ïŞ=¯5©9Kr×h“ ·†.U¸«£ÁèSïôøìÓhØûŸn»ÕÚßßÛk5×—<îştù1UÖs}ú¿¼¥3}’o "›–J¥RÊ7W×Bš¹ê©Uÿ`£Ç0ßæ©j»úçyQ¦¨’f[0êrEÊ[¤fx¤AP¥Á¤bı¥êÌ&rÏRmí*aur	ú.”šLlŒ¼7è>™ªÜ-×e)©¹¤!MÀÖ€&¾Å¨z#Gñf|& ˜y‹N²æô,8_•·ƒÓÊª|×çı	t]ëˆû
^s{AM’Ñ©	^zÄôÿÒµX‡RØ‚´Í°K­õP@)æ:ÔÌŸ.i`äNbv ç¡Ôœi#EÍƒçC»›¢©¦4r`›9°­X3ö.vº)VcŞÆ#¬Ñßı±cVÊrv•û\ÜóàuÕnş+W	¹9ñ41'şÁÌ‡ŸäÂ+¹˜ÁÇåÃ{¹ğT›æÂ›÷ù„eOòµß¡9ñ“|íaª——Fÿ9o?§:çìñC¾{ö$^Uµ|üi>	ëLg¹
L=/¾™sDóé„i³|=˜äT:Êì\xkœo„,'Ÿ“3ôV>»êHLâÛœ{W÷(_‘	nMå7À°İÄsİ"ªËhËKïREEÑ/úúõ‚Ó˜ìÑ©ïÄEpïŠ´Ev¾	né½ ?Îí«µ-±…Àöûz§Ñ¾ÕUoG¢í#ØX ßô|›õ'OuÂŒ¹Ln¢İ?Èêæ©ın!Å„İ<ÉœtQOG7u<d¤6 Àš>ÛŒ@j^Káæªü¼ âXG×P!”×€ûïèÌ;O5ÜgMtØ8§úækŞKõX/h3¤nÜ7Ä.èÛåñÅÂ¾IüT`¡<£ºzÃÑ°{şK÷|t~yzÚ;ı8—…e¼œ]è41e³]üÚ;í^ÎN?´e)8ZdÒ“TÉŒ¼GçÙqK›|èõ»äzÁ¶:8x(ZÁÅ¶FÌWUÊX’‚“Aï8ÂLİğ]šÅ HpÀt¤8íTl Ì¾ÊØHá-[*9®íÙªm$’±@‰Ùê-˜zÜ¥v°]–J÷ŠîeúˆœT‡e»ŞÀ¨iH%<·P,èSœwyÚïô.ºĞ#ô-8g]ûlTEîgNeÊÒ™ÿév~ï—.9=;îö;¿ÁopîŸÎ;I*ù,r´aÍ%höb»ŞóÌ¤ÃÀ$}u—¼bG0A±%ü¸[\>ğ‹4‡Ÿ¦’#1İÜ®uR€©Äw°`60!gÃªmYTøó-(—Vpöÿ´XQ¶âƒÔg
ãkNœ¿@q´©z!èÏ#eqş*Ç¨U‚Œ»^ qÃ7l¦ÌJ£3Ï/à-2—dID—xlşf‹\`p%Xü€¹¹Ô´aIË—a„G¨øø°:”¥y@$èæ½nàñOaßnLĞÛÚüÈ_q@È«+À;fğ R®	êô\Ûç”ÛX­©xêŒü—º6˜‰aàï**gB”ÿGŒ³-¨ÇÒà7è/~DØº„Jzd›x<)†…tK5|Ø“ñ#qEÅ•Ÿ‹Â¨ê;6~L§º˜º¶ˆ=áI˜Aüfûœ™F­Ç°ĞO]=]õÅMZJ\0R`Î_^Sº£˜ï*`<UJ5Tò‰k›=Ñ]æñ2|0İ}Éò‘ÁDİòÁgúğ‡‘(ÃÙ+ÔÛ·4²³WÃaS`øÑ€o5u/ğÈØ;ˆÄŠŒu4. cBu€@¡šæâa”¥G,ß£ #6(E˜€rù ¡+0´Ğ(/ªè1à¯Ìæ•`ñ[úxo»9éFg£şÙQ§Oîg:ï×mD¡Úñ0q0À¾sÓt•a¶Àˆ†‰F°GæQS¨RoÂÛp¯X<Æ+_a¡5p¡(0`Vôşl
#ö„—{^HQ(1XP<¼#äms¨ªCcÂÎ»ıunÃ(¼à(Ÿ%£lP…¦ GÓá­e÷:4ï2,èîa‘‰¶`›BÚQ¨í*l€êäXğG+dÁ‹K»d½‘Rº¶ÓAØs…‰x®ğ¶	zlêÀX/”†uï10YîM‚Ş‡~ÊÃíL0¼¡ƒnjèUÀä¡[3Û÷@¤|©‡í“w
˜¨ÍU1˜¬¸#{$šè[À>èÌËŒ™Ù÷ôNx‘mò…w?ò¤Ç#ünËñe†­0Ä[N,Ë£«.+øé=ãêşâ;KbüéÒÙ˜JvÂ–FT–"ŸÅSV#Ñ”¥ÀD,e&¤<CHÙ8Êõ²³€Q”M°ã<Xw3l?Ù ÙÜÙÚinŒ¼Û9İÇLÖ"£ˆÉZd/¹^0Y-ÙˆóæèL¤d->'Ù Ms S1’õèd„d=z’­ä`œŠl€ör Sq‘µèTTd-:Y‹NEDÖ£'yZ’Š†l€¾ËƒNJo‚şœîçRØ\ı|ÈÓÏTüc-:ıXÏ›æ‘f:ò±Š{l‚næÃ<ÒOG<ÖûÙ\ª•Šv¬E§bëÑN‡•Šs¬§«~}ùàe!\ê‘ëëërOdÆf×rx²L¨š8]È%ÍÃCßÛá¥êÁ}\jàU³L	‡#XTTQ›ñ?Z¤¦’]’áì—T0ÑqQ¼l$Îš–„
ø·ÌO’¯åòSâu~-Ë„,8ÆG-uÁö9‹ÄÉÈjâ”e	ƒpCÀY,k?7m¼yXÖ^¡Z~Â¾Ì‡—2ÿ\AÄÂXÃŠs'~}ìğpQsy !Ö€e¡<"ñ2!‰­ #.¼F'š™À:@¯åà´6Y­a0’ºÆw¬+bE2¶ş:îíêˆÑŸ‹ª¼HXexq6øƒ!Æ¿(Üh‹{ë#”F{…(¤+!Rœ“”L…Üâ9E¹‚·ŞÃ¬ê;âš)l•|ùr°¢†@SÿtóâQ¿Û9ı†…È¯“‹‰ ‚Ãã>3@¦Àœ„1ÓWÌ‰ˆ‚M|Ãx<Ñ°^0ÿñ²G¾Aãø©sôŸ‹ŞE¿Û–ñ˜7sm:s|q6ÄH…ÿQmk¢O}Wá‚³¯C¶ğ8¬{tAóÎÉlÅB›ú:8)†~„«.¾_:ıËî°]®”Ÿ#˜]jömÍPÆ¦Ò¡?6uO	–ğöXQo=İ3ğšşSÔèy”ä/>D…P}šØ +òµ5ä9A÷‚8kê±È5t4öÉş.,]xay é2Ã4H£$—ó¢LJ¶Kš1œ«›À7“p®œ€o&ğ­Ã×PüğufÃ×­ªd;^»üïàz7|Àjm7z=Pªp/?‰1“/D¹¿%ÿ|âïH¹1ÿg5[0x±´¦dKÂdÃ—7(ESyrˆ7–Ø,LD(f>K%&Ñ6|¢ƒšÉJüN,WÑñMĞ’¹Oœ ë#x‹Ü§…ª€¼pbFÈãÀØı=ğ—s|ÁÓÑm^ã”n‡¹ŒètŸ…ƒ
’ıˆP¤ÔT…‰YÌÊ‰…ÕúşÂ·Øßd?õo­<[b´e©\	››Y>Åë³pYƒ¡bTè¥à`„2vAàá£šà›YºÆ|Ã_šo¾€¯Ì¦'ŞiÖm¡Â‹éfáZ,´!ê?î~õ.º'm¹V|JMÇ8F¹!/vv*^Z0B‡×}ØÄİEîñ„Z~P˜‡LLÈÅ^K§Ê>Å€kğè.xİuu9¸!WÇgŸNoŞ^u-º7_	Ü#6Õ±8ş_~Âí>ìÃXDjSp•Qëz¾å™Ğ>îcù_àÁÑ¶ÄÇ…¸pÇIZ‚~‹…èaâ½›<o¸çÖjbß"\üJM&Ş§%qK\ï2ßËß‰ÅÎ’?®fç8şd‡7¯ì…É½#Y_
kµùcG±»å+Bø]Ş®F©øÍ›Æ…Œ‹ÊœTaî†¥,3qËãë¯sğXÀç×ÄëÅoäÎ!ï;˜jùéÇƒæœ¯ ¥W}CïÿO”[Š[ä—}ÿÿıŞŞÒÿ¡ùCãÙûÿİ½âıÿ_Añ…èƒÄ}êºê8RéÇ`®ûº¡ereÌ.?ıúëœ”ßãr¦ü#©õ2×`ƒû=¤Öş6ÔŒ?ƒçfG3œ¹"Iüq¡éÁ.¥Q^/€™…ùZöŸ–ëß`ÿ­Vë‡Œı·ZÍİÂşÿ’ÿ#4Ñ÷°±…1Ög‡RœÎ<M·ÓInÒtŠ©x³L±G¶“ÅE0iVêxGnØıxÒ=…lçdĞïa=ŠeŸ^ŒÈß;–t~¶ø¬ Õ·ü
Ù†¿ï®nªx)³Ûvøm'XH¾“JâZÁá.~]õ>ÒY¸XÁ÷&ANª{w°ÄTVÉTK$ï‡S™x/î¹°q)•Àåá¿'rp€>Œl{ø³M,zOR9­O~Kj·D>í~’«ï²¥OmÔm¶	2ª*š†©ùçËİÑ.”—‡½§>WàK˜4–qw‡iN¥’«k/j4fœHl HpãÎ¤’,…éaşšÎWc>*ØšG¾Áh¥ñ‡Ø‰R©ƒíBjÀÃ”“	gÿM[ñÈ6h
^â-àiW]¾á­¶}¼uêT Aa2,`ú[B--Pº0:ì)A!>ÂÛåZ¯s.ğë}Ê> åÍü7Pó@©µƒïâ½OäO ÜxÅe2Ø‚Aª?8*7Ş‰RAƒ Š„Äuu†º3İ…DQ½¨¿$èêó¾1 {Ùí ×ùh–Jaâ›7ü{?‚‘È¶ ’ò1ŞwŞæ-åf”àÊâû½JÔ•ê¢âPÉªÂAårYU8Üââº¹¨ğ9Ş²¬D½â
!şˆêË°ë¸®òÈ‘-mM«ÉQ!Œ·Y™	¨ûµC|Q¨Ç‰n(‹#Zÿ–„Õ¾¦#8	ÅäJ |––ã ï9¸©³JÔnXäuTÊÏKÈkú ‚N¡F¥’ë÷3´3:,]êù®…†6/V‰TPATPATPATPATPATPATPATPATPATĞÿ?ú_«®ım x  