#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="4234171318"
MD5="71af33285f3b4bb19670eec11a041e61"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4018"
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
	echo Date of packaging: Thu Mar 31 13:55:31 CEST 2016
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
‹ 3ıVíkSGÒ_µ¿¢³Òù$l	$Œ}dG!THÄÉ¥ZvGhÃ¾n`Bôß¯{fö‰$ü‰¯JS£éîé™~ÏÌ56Ÿ=yÛÂöfg‡ş6ßìleÿÆíY³õúÍ›Vskëõö³­æÖ«×;Ï`çÙ_Ğ¢ Ô|€gšcøL[÷Øøÿikl,Œ¼F0û»äßBYåßj¾Ù~[kù?y+·yi:›ÁLQÊÀ>š!¸0ßwı@AÍ€:S”ÑÁIo8tºíJõR˜£ÙÔÊ–Z“c“ÃŞ	¦ŸRØGÏõCwNŞwÇ“Gãvå>óµÛ¶\]³fnÎÀÃã“0}í¶ÿ…ÊR„û) ÿÜmo†¶·iéMBFÄ•£ÃÑ°:|Şg¾8
üMÎ¡xVÌ	¼7ÌÎù>q¢1ıÃI¿÷ÃIçä×É°3ş±o™—»•ûP² ]ˆ¦¢ö:ıã÷mÃÔ,÷JQÏ7p2c–W­Á½¢k!¼}İãwÊi ]±]¨¤2‚zÎ\/4]'¸€3İµmÔİEÑäPüY-ùœıQ¯ÓD5ˆÛªA83 nÑ•@{MËI¡Iiæß0ø:C.D3 j°©Y!—d-¡ Às]«–£A=€E‚Ğõv;!Z¨¥”
’N‰Ş QäáÒ˜$ÌÜ[tßô¸ù:“_1NüWîXq‡ê0ò!äšè’«XàFÇàM‡…Æ£à¸S¦sC‹±tF×ƒâŒØµxBİbš“‡f¶Ş¡,Y‚o2Óq‡ïÒ(´–r<Íè¶A¿Ğ¦Cæ»ÊíÌ´œ¡…7Uh·¡¾°†O::1n&¼$-U¯CqKu})ù©¥ƒ{{gÍjÃRDîî\pKÁÈM
t0œ|è?LF½ÿtÛÛÛ;;¯^m·Ç<ìşpú>‡ú{ ¿œÓ™9ı¼HìT)•J9ÛZ=´>kzí™¾Äàzı9SmÔ¾4]1\cœ9…3¨”¡n…ĞRi4“T™>sAí9ºë“­dŒ¢§¨ïB©aêúhÀè‘Q÷”©Î]mCU²šMeŠ>Û4r8©ŞÄÓÂ÷îf_“ã«{lóUc›*Vû_ÔAr—nÿ|æö‚™$dÀ®lô¼“Àü=
ë1f Y”€ñi°¡ÏœÇAJ³ƒšEWËT¸ŞúfÈ8 LÉ•ÙÚ5¹[tÄåLôLa&ñ‰´¥Ú5¨úüù‚Ø_ôĞØLQÈ«R+ÃæŸ×µ|íË©ıi¼e”›ø“šÍn4+ÑvüÖgL¿Ş'¨ Jƒ2nß¡
‡º÷Ïá"±J4õ†óœ“CÃ£²*ê"MhP¶@}Hö	ö6Ğà¹}å;uòÄa=Ó u |ŠI|¥¥3ƒìj¢fWá­)/à{?ye»`e§‡ã…+S¸y-”e2×}o4uO~îLNNƒŞàı\Vñt6‰3r–ñ7ÛÄ/½Aw|898¼k«ŠLbå>‰( Ixç=ÈÚğ®×ï.rù2û	cCÆ€„–ëL‚H×13ÌÒ¢â†½Ã"èT3­ÈgEPm¢‰)³Ìµu/Ã´aÚ¥•CsÒ|ĞóİĞÕ1ÍLG	=I\ııAºè¶ôö	Ä­f†…ÍÈ×½ ¸UM:VÀ(÷P,ÖÜ„ätĞïõÆİt<TZY,z 4ÊÂL-í*ÈÃüÔí;ıŞÏ]vû_ñ/ÆŠ'aR–Q‰ähWîOÑdæJ‰‡·âXÖ7¤Û™H©4\„†R’–Š¡/XL”»È…ØÒ×,Ê@¨|€E­;î2°tt\ŒP‘Gë@‹Ä8+İu&ÂDñòZ†^ûîñ¿•ŠV^¡i‘á¥ãTÍ¸Â<.…X jw,HÇWÉ?…Z!É”×G%Zş|‘PV‰–bÄçŠ¶sEUÄá?À¡+Ã˜Îd6…Æè3ÛÅ+•l@<?`á;ƒóx&EŒØ¼—K¼5-ÃˆæPÌš’wyÅªy(^¬5¤C”skÂÅáœ¡ïZ"%ß im-Ôgğ;ó]@0›N¾¯é”ºcâÿ#…ÃJ °òÇ¿¨¹ô‘À6RÏ×¦L'ÂÊú’’|İŠTèË;ğ,M§TRÃ,3A#M'æ/Ù•)âaÜ)ï²Ğ ğ«qbsîâU ;¡©G–ægm$	i˜F,Ÿ)?ÏAJƒ/• p?uÌÀI½§¾ksè©é!Çá›©™XJ–ïušN„®4ÂV‡“ER¤nä(eÃ	¡ëñ¶i¸ıä	Ğ×Úf(=‘@òAÒÄîu²/(c`&‚à‘Ãği‡è‘¤Nd_’ 2$EH‹¨¼C¡+¸µÈT˜Lt'ékVàòIıšİİº¾Gád|<étúp;3ùº¸n©?å”,õ½ÔÕ€†Œ`L0Ü!³…*õ¦œ‡[ÍáGd˜.áş
£ˆ­EÃsê¨÷7h`W¸cñJ86ÚÒrPŠB‰q‹Ğ‚Òí-!çÍcº‰ÌÄ‹uûïÜ†Ix²j²‡DˆHBÓ¢íqnƒ[“6š/³Ä[Ì\É\[H;™“´]ÇŠª‡‚F¼Ó4i".óÅì¼‰Rú®K ^¹ˆãHá-\õØ6‘°Ø^ÄÆÍğNš,÷&rõ±Ÿ
©cÓ)Uò&ê¦A^M—5s£EÊóGâG„)î(44Q—«¢SÜ‘İ!Ö&éa…„…}€™{Ën„Ù€?øòOz8g·m5=‹/Ç'”•L®ŸÜÔ¬<Î¡« ‰/9¢Îc?v|ğÉgŸ|pğ©§ŸpdğèyûÈtÈ×bç•&ÕVç•aç•m¨ë°ûûøû/¥ûneºäEŠš;ì©Ï’‚8®–2•Â|Q•&"~CĞÊàe‚ór<ã‹X±"®˜Wy¶kÀ‹Ë!”GÏ¨–‹eYcÆ'Ù_S-‹B8.š—§:ç<yŞß_X]Q%œ
v„3/­Ÿ¦¶.ËSqGäÏŸpRÌHQU™o×§«5	÷Ñ4¸\qà¡ïçéZW{|İáÀ“œŒÆÇÃ/<%û‹NÌ\qÑ7!i´WˆB9"å€(v’L®)2VªtMÕöÀ·s°5øãİ3H=ıêæO$Äƒ~·3ø†…Èïß„—¯’@Åöø·Iš“0†QşNÄùÍ4²0Aá4É°ğ8ùıi¾Aãø¡sğÓ¸7îwÛ*%&èpÂ™ïFW3/ÙH u	ÿƒ©×Ô¼Š|B-^§—)ëŒaØ9é œ
í*2ÑIY¸õJ¸ø~îôO»£v¥Z¹„0¶Ôİëº¥]2å]b¶­¢Ktv©é×¡ZtzŸ0=OÆåØ(sE.&Äé ¬imPÏ‘Ë“Ç…¹Ûõs\4w`gs¬±WåUš%µ’‰Š*”°oZ)8W7ßÊ‚såDøV~{ÿ9¢ï?oa,|¾]S\/lWş-ïÎğÚ–„E/:ª\Ç+÷bOç˜k·×ğÏ{~é•æüŸµ"¢|âñf‹01Øğ|Š¤hcí
#
DÜXR³\ˆHÌ<Jebh?ÉáÌ°ÒïqñpÇ7%Kæ>qJ®èŠİ§Cª@´P¸ÿœPEŒ„±¢¬ÿWúË9İ=ó~r›„ã2}!v;ä*Açx–d×‘@AUÎTÃÀ,¢r&«z|½2 |‹ëÍ®cÑzéêåAŠÑV•J5f7›=I¢ÂÇiKj¨B7ôÚ&Ÿl£áâ<~Ô2t³yknœïåéæÒÜ‡tUM:½AÑm‘Â‹p³0×BmŠù»ï&½q÷¨­ÖëÒ§ÔMªœ+Mu±³ÓéôÜŠ^÷ã§¸»ÄÓ‘!1'’8HX20‰`‰Ñ
Ï•vc^ÑŸ|¥$ŸÃœ/àìğøÃàâåY×	™A½tÄ|Ğ tú/÷ÄŒ
à\UpVĞìHñ&¡|Yän–ÿBOˆ¾v[|ŒÅµ1oªd†\WC2o„ÔQ|O‹ÎÛĞ˜MËKàÒ—=ê(ó¦'·Äû.s¿üNê/ùcÁp­æø“Î^MV¤Âêö èN1°. &ªWÜ ,p½x£–ôÒ7tšrŸô9«ÅÜ+EbâRáÏOu¨ÌøYµxñõÜœóµ£µVî¿ßmÍy­<İûß#íšQÅ÷´ï_¿zµôıwëMóÁûßÖÎúıï_ÑÒ'*»™.İó”Ò÷2ô\F¦eFU®ÜüòË*o):W¾‡z¯ğ8A^@½ÿğm,Ô­##8¾ü½Ppày£™/ºÄ±aÊ>cÉXO‚ÙÊ³uûsì?/×¿Áş·›[¯
ö¿½½İ\Ûÿ_òş?6Ñ·˜O»Â³}%íBÃtó]¡i³|­…³Ú]°Y„KÀ”2&tÉ8ê¾?ê0ëûİæVØ’ÑÁéÑDBŒø«Åäwx˜èÒLfô—ü
6ğ÷ÍÙEM¹WJ4d¹®wÀo‹0'ÚSJâZˆ!º ãıcüÈQÜ¥€r$j„7˜-é’T¶×İ;q$OKCÿÓğR	=ıß	vwÉ…ÁFHÿ¶Áa·©ªd|êK¨7_‚:è~Pk{Eì‹{ºáĞ¿m Bõ}Í0¨·ªşxú¾;ÙB|uÔ{?èôºé]H×­-¥$p¸­W³ãÔ?Â\-¥££)„lY«6¿ˆœÀÊ-3ÓÜ‚8şoj¹Xbn pèŞYå}gí¹àŒ¸=‰Å(…wó“iê	Ì1¤œãA\C¨I¤&õO]Ÿ+šÉ©àŸ·9•Ä/èE5	õÈØİÕéúğí[P?àNSå2`˜Àc¯Iÿp8œÜÚX’!œ"£zéÜ¿‰¹Ã¹ËÅN1½˜¿$6èì·zB…&“Û$Ëiğİ,•âÎ/ø÷œş‘;Qä Ü!=ÑØàœòŸ¹¾#Y¼~UM–R[„“¬B–<,DårY…œn1ºi/B>¡‹áj²*®âG2_\Ç÷µ;®ˆÁRn¶[ª*„ñ²(3A‘Ô¾¾O¯Š¥z,fCğıâ	²°4ú®Jˆı9ñœiôY5a3©îGñ³:ª)QN‡±»q;Óè´ ¶HÒgaä;d[óu*¶në¶në¶në¶në¶në¶në¶në¶në¶në¶nëö¶ÿTÍ’ P  