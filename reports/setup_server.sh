#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="2796281525"
MD5="0385a6d9d7e1c9d071e5972d93d8610a"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4055"
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
	echo Date of packaging: Fri Apr 22 17:05:19 CEST 2016
	echo Built with Makeself version 2.2.0 on linux-gnu
	echo Build command was: "/bin/sh \\
    \"--header\" \\
    \"../../../MDSip-tests/reports/setup_server/makeself-header.sh\" \\
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
‹ ¯=WíksGÒ_Ù_ÑY8È	$ÙW’Ñ…HØ¡!J 89YE­v±Ñ¾nzDá¿_÷ÌìS€ìÄJruL],v¦»g¦ß=3×Ø|ñìmÛÛİ]úÛ|»»•ı·ÍÖÛ­7;ÛoŞì¾}±ÕÜÚİj¾€İ@‹‚Pó^há3m9ÜSãÿ£­±°0òÁìÏ’kçÍ›¢ü[­æÖØZËÿÙ[ù›ÍKÓÙfŠRvg†à:À|ßõ5êLQF‡§½áxĞ9î¶+ÕK-`f3P+[jMMz§8f˜~fHawë‡0îœ~è'ßŸŒÆíÊCæk¯m¹ºfÍÜ œ€‡'§`úÚkÿ•¥7œôS@ş¹×ŞmoÓ6Ó›„Œˆ+ÇG£aÿl$ÖùùBà(ğ7ùBÅ³¢`Nà½apÎùÄ‰ÆkèMú½ïN;§?M†ñ÷ExË¼Ü«<€’ èB¬Ğ0å¨×éŸ|h¦f¹WŠ¢x¾é„“³¼j]áİ;è¼WÎíŠíA%•Ôëpîz¡é:Áœë®m£î^(
ˆ&‡âÏºhÉçì×z&ªAÜ®PÂ™ u‹®ÚChÚN
MJ0ÿ†ùÀ÷ºpÉ 
˜UƒMµÈ
¹$k	 iëZµêÔ(¢„®Ï°Û	ÁĞB-¥TtJô‰â.İ€I²ÁÌ½…@÷M‰»‘¯3ùãÄ%ÇŠªÀÈo„k¢Kî>`A€ŒÁïL‡…Æ“àÈ)Ó¹Š¡ÅX:£ëAqFìZ<¡n1ÍÉC3ÛïQ–,A‰™Ìtäğ½B…ÖR.ƒ§ùİ6èÚtÈü`O¹™ƒós´ğ¦
í6Ô7àâöÁpãiAG!ÆÍd-IKÕëÑPÜR]_
B~jéàşşãY³Ú°‘»;$ÜR0r“Â'{ƒ£““QïßİöööîîÎÎvëiÌ£îwgr¸¡±GğËW:3§_Æ€ÄN•R©”ó±­Õ³@ë‹æ©×~ã¢/1¸^ÉTµßO‹š®®ƒ1ÎœÂ9TÊP·Bh©4šIª¿LŸ¹ öİõÉV2FÑ€3Ôw¡Ô0u}4`ôÈ¨ûÊTç®¶¡*YÍ…¦2Em9‚ToâiáŒ{w³¯ÉñÕ=ÈG¶ùª±M
«ÆıˆïGê ¹Ë	·>s{ÁL2`W6zŞI`şÂ„õ3,JÀø<ØĞgÎÓ ¥ÙOAÍ¢«åT¸ŞúfÈ8 LÉ•ÙÚ5¹[tÄåLôLa&ñ‰ÄRíš	Ô	G}ùrAì/zhl¦(äU©•aóë5A-FDûíÔ¾ÚÚ2ÊMë“šÍn4+ÑvüÖgL¿ˆµOPA”e*Ü¿Á0òê^<0Wá"±K6õ†óœ¦“KÃãò*ê"QhP¾@}H™	ö6Ğ”à¥›}åu.ŠÃz¦A
!@ù’K›gy€©‰Z˜Û[d„Ïµ7$½`ÍØûÙ{#Ø{;;/Ü›ÂMl¡<“¹z£É¨{úC÷trz6ôæª°Œç³L&˜‘³?Ù.~ìºã£ÉáÉà}[Ud"(IŒ@MÂ{ïQ>Ğ†÷½~w‘Û—°H2$´\gDºÙa–`0ìA§šiE>+‚’˜ˆ‰&¦Í2ßÖ½Ì¢3Ğ.­š“æ„ï†®©f:JèIjàê×èÒM·¥ÇO n53,0#C^÷‚"«št´€‘6î¡x¬9È„älĞï÷Æİ”*­,–= ea¦–väaşÕí;ıŞ]œuûŸğ/Æ‹§aRšQ™ähWÎĞdæJ‰‡¸âXÖ7¤ìÌ†‚¤T.BC)IKÅğ,&ÊäBléke!TBÀ¡ˆ¤Ö=wX>:.F©È£} Eb¬•Eî:¡¢Œxy-C/„}øßJE+¯Ğ´ÈğÒñªf\a.—B,Pµ{¤ã«äŸB­dºÖ'%Zşr‘PV‰–bÄ—Š¶sEUÄ	?Ä¡+Ã˜ÎdF…Æè3ÛÅ<+•l@U<?dáœÁ¬y<“"Fl^ÓË-Şš–…aDs(‰fMÉ…»¼jÕ</Ö‡ÒN‰!Ê»5áâpÎĞw-‘–oĞ´¶ê3ø…ù. ˜M'	Hß×tJß±ñÿ–Âa5 Xıã_Ô\úH`
©ç¡kS6Œau}I‰¾nE*ôå=x–¦S:©a¦™ ‘¦Óâ/Ù•)âaÜ)ï²Ğ ğ“qbsîã]àr4*2BS,ÍÏÚH:Ò0‘X>S~Ã”ß* ?uÌÂI½§¾ksè©é!ÇáÌÔLGì	%Ë9C¦¡+ğ‡•Áád‘é‚9JÙÇpBèzÌ6ÙO }­m†Ò	$ï$M ¯¾ Œ™‚Ä†O¢ƒF’8‘}I‚LÈ1| -¢òA„® kqQa2Ñ½¤¯YË'!ôkvëúw†“ñÉ¤rØéÃíÌäûâºMP¤vü¤S2Xê;7z©«±0±ˆà>™-T©7åk¸Õ~L†éòWEl\(2Ì©£Şß ]!Çâpl´¤å …#‹Ğ‚RöŒ¯Ícº‰‹‰7;êöß7¸“ğdådŠ‘„¦!EÛã«nMb4ß2f‰·˜¹’-¸¶v2'i»UU˜Ó4i".óÅì¼‰Rú®K Ş¹ˆ#Iá-\õØ6‘°`/bãŒfx/M–{¹ûØO…TÓ±é”ªyuÓ ¯‚&Ûš¹Qˆ"åù#­G„)î(44Q—«¢SÜ‘İƒ!ö&éa•„>ÀÌ½e7Â‹lÀ¯|û‰'=šˆóÛ¶šÇ—ãSÊJ&×OnkVAçÑÕ‡Ğ‹Å—Sç±Ÿ:BøìóƒÏ><øÜ“ƒÏ86xòÌ€İ1òµØ§J“j«O•aŸ*ÛP×ağ÷/¥ûneºäeŠš;ğ©Ï’¢8®–2•Â|Q•&"~CĞÊàe‚ór<ã‹X±"®˜Wy¶kÀ«»åÊ“çTË‹Å²¬1ãÓìßW/‹R8.›—';Ÿxú|p°°¾¢Z8í2!i^\?Ou]–'â¦ É ?ë¼$˜‘²ª2ç®OWkrÒ4¸Ÿ\qì¡Òê?¥»]}øñûå„`4>şÆÓ²?èäÌ~’F{…(”s!R8‡’L®):Vªt]ÕöÁ·s°5øõ×½3HMıİ3ÌŸIˆ‡ıngğ"¿‡¾Jìñ ²Iš“0†QşnÄÎ4²0Iá4É°ñXùÃYş‚Æñ]çğ_ãŞ¸ßm«”œ Ã	g¾]Í¼Hd$Ôa$ü¦_Só*ò5.µx­^¦$¬{8†aç´s<‚r*´«ÈD'e!ë'”&pñıĞéŸuGíJµò at©»×uK»dÊ+ºÄŒ[E	–è"ìRÓ¯C3´è.ô!Yô<—c£ÌU¹˜§O€°®µAıäŒøˆÜ<2Ìİ²ÂíAsv·0áÈêû÷T^ù7¡YR+™¸¨B	û¶ •‚suğ­,8WN„oeà·^"úÁËFÃ—Û5ÅõÂvåŸò? `IèYô²£Êu¼ò x:Ç|X»½†¿?ğË_¨4ç¯åS'0[„‰Á†çT$EëWQ âÆ’šå‚@DbæQ*DÛøI~g†•.xŸ‹‡;¾)Y2÷‰Sr}@W•è>R¢E™@&T#a¬*ëÿ‘şrNwĞ¼ŸÜ¦áø„L_ˆİ¹JĞù…åÙ}$PP•3Õ00‹¨œI¬Ş¯Åıf÷±h¿tó(Åh«J¥/·>¥ùYœÖĞÑ¤†*tC¯nràh„*mAÀãG-C·º¦tãŒ/O7¾€®*£éq§7(º-RxnæZh¡M1ÿQ÷ı¤7î·Õz]ú”ºIÕs¥©.vv: [±ÃëŞ}»K<İ1â1s"‰ƒ„åæ1,#Úá'e İ˜WtÌ'_+Ég1çgÃ8?:ù8¸x}ŞuBæ_PU/İ#->h:ı—{jFEp®.8/hö¤x“P>ˆKän–ÿBOˆ¾v[|ŒÅõ1oª\¹® †eŞ
©£ø¾·¡1›¶—À¥/|ÔQæmOn‰÷]æ~ù{œÔ_òG9bÁµb˜ãO#øòj²*V·EwŠiŒ€uùC1QÁòä`ëåÀµ¤—¾ùãôÔ”Ëø¤ÏY-æX)_?Õ¡R?âçÕâå×_äï­µòğí^kÎ“håë¿ÿ=Ö®UzÏûş÷ÍÎÎÒ÷ß­·ÍâûßæNsış÷hé•½Ì—†îyJé[r.#Ó2
£*Wüq•w•+ßB½Wx˜ /G Şü6êÖ±œ\şŒŞ'8ô¼ÑÌ]âÇØ0åŸ±d¬'ÁlåÅº}ûÏËõO°ÿííí·û§§”kûÿCŞÿÇ&úóhWccv ¤ıAh˜n¾+4m–ï±µpV@»6‹p	˜RÆ„“.GİÇİ&aãa¿;ÂœŠZ2<8;HÒ¡˜ü3\úYŒşšßÂş¾9¿¨)J‰†,×õùU&CûJIÜi­ˆn¿ø-ÿ?òCpé ‰á¦Iº$•íuD÷nÊÄÛÒĞ¿Çü»TB—Gÿ‚½=òa°Ò¿mpØ-äFª*YŸúêÍ× ºÕÚ~{à"S7ú·D¨~ õVÕïÏ>t'[ˆ¯z>¡ÇYä"ÍeT&§İQR©d`†Ò­­ÁRÂ™Î&	jÜ™T³XÔ?±ùZJGG[Ù0²Vmş&r+Ç0LysË°)Ï“ ç	'‡ÿ›Z.º¨)t.VÀûÎº|ÁWíFôX%Ö)©Aq7?§ş×ÀC*]<ˆ5‰Ä9<u}®õ&§‚Şåì{^½¢÷İ¤y¨ÔÆŞN™ïŞúÅBõÓH\Åa½&ıÃáprk_`Éá;HçşYÌı3Î]Ø.vŠéÅü%Á óŸ/è1ÚkLn“Ì¸Á¹Y*Å¯^ñï9ı#9Q\A"å#z,²ÁWÊ”à=ÉâÍN5ÙJm:N²
Y®a!*—Ë*äDp‹ÑM{ò)]QW“]q…?’ù
ä:¾¯İsE–®f»Å¡ªB¯‹2I÷ëôÆYªÇ±ékw‹#Vÿâi_Ó”„RwU>êñø Ê{NçFú¬š¬“¼îÎxÙ/Ù:E•ShìnÜÎ4:—-è0’ôYùÚ|%®Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûÿoû/­³ôğ P  