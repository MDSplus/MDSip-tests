#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="2947791638"
MD5="22f1846ad9f17f57a39b7d37f227d56d"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4614"
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
	echo Date of packaging: Tue May 23 11:58:10 CEST 2017
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
‹ ²$Yí\ySÇ¶÷¿šOÑô|%l	$çX¼( ;ª+@… NPªÑLK3Ûa¹XßıÓ=;Ú&6IŞ«9•¦û×§—³ôrº©ï¼zqÚúqo6~ÜÛMşéU£Õh4vw[ïß7_í6vßí5_‘½WùÌS\B^)–æRe9n]şÿQªï0êùNÍş*ù·Ş·v[ù7{ï_‘İBş/N[?ìŒuk‡Í$i‹Ğİ#¶E¨ëÚ.“@3HJÒğè¼7¸8íœtÛåÊXaÔRLJäò®\òFÇ½sÈÓt7‘%ÑÇv=rÑ9ÿÔ½ır6¼h—Ÿ_ûmÃVcf3oÎÎ`üÚoÿ”%‹ÎÎú1î·w<ÓÙ15¦;#"séäx8è_E;Ÿ_ ö™»Ã‚EÃgs„÷iàœg¶¡<ê÷~>ïœÿ>t.~Éâ}¼_~Ê€¢ ta)OÓ%é¸×éŸ}jkºbØSI’W·¼ÑŒN¥J$UñÈ‡¤{öQºdÊ”î“r,#R«‘+ÛñtÛb7äJµMt÷F’ˆ  +ü¬	Š>g_k5¬¨JBš‚x3LIÚ4v'F£Ò0êŞQ—ğ~z6Sâ3ª‘ŠF'Šox\’ÕˆÌ±m£šâ)4
90Ïv)$[ÑO‰9e$3½¦Ğ†±ÍhÀ–Íì{ÂTWw€¹í»*¾Â2áÏ`Ä²#TËÀĞox$E")è=£ŒÁ@‡ğİ¢¶#¥[Ó-òâm‡dk„¤ÅªU¬4šš÷²¤Q‘p©
#üú:!‹º&ó%	µ,kk‹8ŠË(QMû÷¨Ëö¥û™nPruŞ !“v›Ô¶ÉÍ9 šÖCTp&"_ÚQ¬ŠÏ²BŠíb)}ÚÒÌƒƒçµ&5giAîmà–ÂĞ¥
wu4}îŸ}{ÿÓm·Z{{ïŞµšëKw¾ü”*ë¹>}†_ŞÒ™>É7 ‘MK¥R)å›«k!Í\õÔª°Ñc˜ˆoóTµ]ıv^”)ª¤ÙÌ‡ú„\‘ò©iTi0©X©:³‰Ü³TÛE»JE\‚¾¥&ÛcïºÏ@¦*wËuYJj.iH°5 ‰oqªŞÈQ¼Ÿ	 fŞ¢“¬9$=ÎWåíà´²*ßõyD×:â¾‚×Ü^PS€dtj‚—1ı?t-Ö¡T¶ m3¬çRk=PŠ¹5ó§K˜ ¹“‡…˜ÈÀy(5gÚHQó ÇùĞî¦hª)Øfl+ÖÌ½ËnŠÕ˜·ñkôßşÆØ‰±1VYÌ¶ÀUîsµ"^Wíæ?s•ğ˜›OsásòáÌ|øI.¼’‹ù|a>¼—Oµi.¼yŸOXö$_ûš?É×¦z9ñwùğàrâ¿ä-àçTçœ=~È×cÏäÂ«ª–?Í'aé,W©£çÅ7sh>0m–¯“œJG™oóåäsr†ŞÊ'bW}‰I|;tïêåË62Á¥©ÜâF¶¥x>¡[Dõa¹myéİ, ¨(:âE_¿^pj“=¢!õ¸îq‘¶ÈÎ÷#Á-}  èsûnmKl5°}Á>ƒŞ)F´÷€ouFÕÛ‘hû¶HEÅ7G?À¦şÉS0c.“›h—Ä¼zƒyjßLH1a×O2'bÔSÅOO
©°&‡Ï6-ZÇã‰×R¸	+ÿ /ÀA£8ÖÑ5Tå5à>=:ÁÎS÷c6Ø©¾ùš÷R}ÖÚ©÷±úvy|±°o?=X(Ï¨®§Şp4ìÿÚ=_öN?Íea/gºMLYÇ_l¿õN»Ç££³ÓmY
 ™ô$•@2#ïÑyv,Ó&{ı.¹^°ıN-ÅAŠVp±­óU•2–ä‚§ådĞ;0E7|—f1(0])NEU³¯26RxË–Jk{¶j‰d,Pb¶z¦w©l«¥Ò½¢{™>"'ÕaÙ®70ºCR	Ï7úç]ö{'½‹.ôÈ}Îcä>U‘;ä™C™²tæ¿ºİA§ßûµKNÏ»ıÎïğœûçóÎ@’J>‹mX ds	š=‡†Ø®÷<3iÃ00I_ÅÂå¯…ØLPl	?îÇ—üÁ"Íá§®äHLwÆ#·k`*ñì˜LˆÁ²j[ş|Ê¥Õ\¤=Áÿ-V”­øÀõ™Âøšç/Pmê‚ŞDˆúóHYœ¿Jà1j• ãÆ®hÜğÍ›)³RÀèÌóx‹Ì%YQ()‚¿Ù"„	?`n.5mXÅòe*á‘,>>¬%ACi8	ºy¯x|ÅÂÓGØ·ô¶6(ÙquxÇÌ€X*Â5Akâ<s«5O‘ÿP×& 31\ü]EÅsOH‚òÿãlê±4ø	ú‹¶.¡’Ù&#BEŠ…á#İRöÄdüHCQqå§À¢0*†úÓ©.¦®-bOx’fP'¿Û>g¦Që1ì4GÁÓYOW}Cq“–×Œ˜ó—×”®ç(æÁ»Š O•R•|âÚ&GOt—y¼LE·DŸ@²|d0Q·|ğ™>üb$Êp¶À
uÁö-¤ìÂl€ÅÕpØ~ôà[Mİü² ö"±bcÈ˜P ĞAh¦¹8BÍEéË7Ç(ÈˆJ¦à…\>Dè
-4Ê‹*zø+³y%Xü–>ŞÛ®FN:ƒÑÅÙ¨vÔé“û™ÎûÅuQ¨v<œp ïÜô]e˜-0¢a¢ì‘yÔªÔ›ğ6Ü+EÂÊÆWEh\(
˜U½¿›Âˆ…=á¥Á^€—RJCoÆyÛªêĞ˜°³ÃnÿcÛ0
/8ògÉhD¡)ÀÑtxkÙ½Í»º{Xd¢-Ø¦vT'j»
 :9<Â‘ÆJ#YğâÁÒ.Yo¤”®mãtö\a"î+¼…m‚›:0Ã¥¡Fİ{L–{“ ÷¡ŸòpûE'ƒè ›z0yèÖÌö=)_êa{ÄdÅ…&jsU&+îÈ‰&úğ£:ó2ã@fö=½^d›|åİ<éñHÉÛr|éa+—ËòèJÌÊ@zÏ¸:Ò¿øîÁ’» éÒÙØKvÂ–F^–"ŸÅ]V#Q—¥ÀDÌe&¸<CHÙxËõ²³€Ñ–M°ã<Xw3lgÙ ÙÜÙÚinŒ¼Û9İÇVÖ"£ÈÊZdWY‡TÖÀ$iaPe£lÎTÖâSá”Ğ4:JYNRÖ£'9ĞJÆ©Êh/:>Y‹NOÖ¢S¡“µèTàd=z’§%© Éè»<èäÙõ&è/ùà~.…ÍÕÏ‡<ıL…IÖ¢SA’õ¼ii¦$ká©ğÈ&èf®1Ì#ıt`d½ŸÍ¥Z© ÈZt*$²íäqX©pÈzqºê÷—Ş=Â!¹¾¾.7ñÀAflv-‡Ğôª‰Cè\Ò<<äøw;¼T=¸ŞK¼¹–)ápd‹Š*j3şK‹ÔT²K2œ‚ô’
&:®½“w—Ä‘Ô’ˆÿ–ùóµ\~Jœ¶Î¯e™§İâD¦.Ø>g‘8@YÍBÆ,aî8‹emà'è¦­‘7ËÒÚYËâ·‚óûğç·Å"D˜!I¬8â·Ñ5—ÇbX†ÊÀ/¹Ø
¢6âşltğ¹Q,
¬ôZJk“Õ#©k|c»"¤$cë¯ãŞ®,}[ğåE¢/Ã‹³ÁŒDşIQI[\ƒ¡4Ú+D!]	‘ràœÜ d*ä3Ê¼DfUˆk¦°UòõëşŠMıææ/$Ä£~·sú7"¿.&‚

TûÌ a˜sÆ0LßX'"X6ñãQğDÃzÁı§ËùÇÏ£]ô.úİ¶Œ§Iàp¼™kûÓ™ã‹#$Fjd(üj[}ê»
„œ}l²…§fİ£2èœwN†d+ÚÔ×ÁI0ô#\µpñıÚé_v‡ír¥ü$ÁìR³ok†2¦0•ı±©{2H°„W¾ÇŠzëé·şŸ¢FÏ£ü o˜x@"*„ê#ĞÄ]‘¯­!Ï	º„cSoO®¡{¤±GövaéÂËHß—y´¦A%¹œ˜eR‚´]ÒŒá\İ¾™„så|3o¾†â‡¯›0¾nU%ÛñÚåÿn‹Ã¬Övã©gÑ{§
×ñò“Ó9ùJ”û[ò'şÌ”óT³ƒPkJ6±$L6|yƒR4˜'‡8qc‰ÍrÁD„bæ³TbmÃ'ú1¨™¬tÁb¹Šo‚–Ì}â]ÁKùà>-Tä…3BFÆ Æèì¿9Ç×<İf áå±0~Aév8‘ËˆNgğY8¨ ÙE*AMU˜˜Å¬œXX­ïo0!üû›ìÇ¢şâå–gKŒ¶,•+as3Ë§x}.k0¢¬€
İá[´ŒPÆ.<|T|3K×˜o¸âKóMÂğ•ƒÙô¤Ó;Íº-Tx1İ,\k…6DıÇİ£ŞE÷¤-×jO©éî(7äÅÎNÅ»Fèğº›¸»ÈÓ !PËÊ ã ó‰	¹ØÃkéT¹Ó§—ŞğÅ®.7äêøìóéÍÛ«®åQ÷Ã0{ÄÆ³:ÇÿËO¸Âw‚²Hm
®2j}CâBÏW <ÚÇ},ÿÜ 8Ú–ø¸÷ò8ÉAKĞo±=L<Ÿ“‡áE8ğÜšBMì[„‹½ÉÃÄs·$n‰ë]æ{ù³³ØYò·g¢ÁÕìÇ_ ñæUƒİ¡0¹’õ¥°†X›¿»[¾²!dßåàíj”Šßü¸i\È¸¨ÌIænXÊ2—A¾ÿ:|~»@<†ü›\Mä}S-?ı´ßœó´ôª oyÿ¢ÜRÜÓ¾ìûÿ÷ïŞ-ıûÍÏŞÿ7šÅûÿ?ƒâ‹Îû‰{ÒuÕq¤ÒOÁä:öuCËäÊ˜]~:úí·9)ÀõGù'Rëe®·÷vH­ÿüm<©';WËg8sE’øåBÓƒ_\J£¼^ 3«ÿ^öŸ–ë_`ÿ­VëÇŒı·ZÍâïü9ÿ#4Ñ°c°…1Ög‡RœÎ<M·ÓInÒtŠ©x³L±G¶“ÅE0i–Öx÷mØıtÒ=…gçdĞïa‰eŸ^ŒÈß'–t~·Öòø,ÙÔ·üjÙ†ßï®nªxÙ³Ûvø-&XùH%qİŠ`‹ğb¿†zé,\]à;’ 'Õ½;Xª«dª%’÷Â©L¼÷ÜGØi”Jàòğï‰ìï£#ÛşÛ&½'©œŠŒÖ'¿%µÆ["Ÿv?ËÕƒléSuÛÂÛÕMÃÔŠüËå§îhÊËÃŞ§ÓN‹‡Kæ%LË¸ŒÎ»Ã4§RIƒå°‡
53N$6$¸qgRI–Âô0Mç«1lÍ£ß`´ÒøCìD©Ô€Áú>5`‰aJIÈÇ„³ƒÿ&†[úmĞ¼œ)ZÀÓ®2º|Ã[mûx›:Ô©@ƒÂd	Àô·„ZZ ta&tØS‚B|„'¶Ëµ^ç\àÇ‡”}@Ê›7ø7Pó@©µı}ïØ}ø@äÏ Ü)Å%1Ø3AªÿpTnˆRAƒ Š„Äuuº3İ…DQ½¨¿$èêË¾ {Ùí ×ùh–Jaâ›7ü{ÿ#‘mA$åc¼Ç¼Í[ÊÍ(ÁG”Åûw•¨+ÕEÅ¡’U…ƒ6,,Êå²ªp$¸ÅÅusQás¼=Y‰zÅBüÕ—a×q]å‘+"[ÚšV“£*Bo³2Q÷k‡øR.Pİ:Q7F´ş-	«}+LGp6ŠÉ• ø,=,Ç3@Şs<!Sg•¨İ°Èë>¨”p×ôABJ)4$×ïg
@gtXºÔó]m^¬*¨ ‚
*¨ ‚
*¨ ‚
*¨ ‚
*¨ ‚
*¨ ‚
*¨ ‚
*¨ ‚
*¨ ‚
*¨ ÿô¿ªé¾ó x  