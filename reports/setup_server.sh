#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3749286885"
MD5="b52b7187b8c757467a3bb99235a4ac7e"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4104"
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
	echo Date of packaging: Fri Feb 10 14:14:02 CET 2017
	echo Built with Makeself version 2.2.0 on linux-gnu
	echo Build command was: "/bin/sh \\
    \"--header\" \\
    \"../../../mdsip-tests/reports/setup_server/makeself-header.sh\" \\
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
‹ š¼XíıW"GreşŠÊÀí» €fïéâ…(»á"O0›œúxãL#‡™¹ùğãÿûUu÷|
¸›Ä$wG¿Dîªêîú®îŞÚö«o;ØŞííÑïú»½ôï¨½ª7wvß5›_7šW;õİ¯w_ÁŞ«ß¡…~ y ¯4Ûğ˜¶î¹ñÿÒVÛöYº5úGÉ¿±·³»—“£ş®ş
v6òñVüjûÚ´·ı©¢=˜860Ïs<_AÍ€*S”áÑYw0ê·O:­RùZó™­Í¨¥µ"ÇÆÇİ33L/5¤°×ñµÏ>vFãïN‡£ViúÚoY®YSÇ9àÁéY
˜¾ö[CeÉÃ§§½î·¶ƒ™»=3|ÓŒˆ+'ÇÃAï|(Ö9O}!pè{Û|!„âZ¡¿ ğî ¸à|âD£5ôÇ½î·gí³Çƒöè»<¼e^ï—æ9 xº+0LE9î¶{§[†©YÎ¢(®gÚÁxÊ,·\¹¢k¼ÓÊ¹¯İ°}(%2‚j.70Û¿‚İ™ÍPw¯D“CÑgU´øsúsµJU j7¨ÁÔôºEWí"4m'&¥ñ™wÇ<àû¸fúÌ€²Á&Zh\’•˜†4|×q¬J†õ jQğÇcØm`h–PÊI:!z‡Dq×Ï$YêÜƒ¯{¦‹ÄĞÓ™üŠp¢ß’cyUs`ä7È4Ñ%wï3ßGFGà¦ÍãYpä”ißDĞb,™Ñq!?#v-ŸP·˜fg¡ÙÌQ–,F‰˜Ìtäğc„zš Ë¶&’Æ…´-«XWó|úÌ ¿ĞşæùûÊıÔ´\\ 7¨«ĞjAu®®à 'štt&bÜŒ×·DŸE-±‹• äÓV<5­9+¹kt@Â­#—*ÜÕÑ`ü©Û?>ı4vÿÙi5›{{»»ÍÆó˜ÇoÏ?fp/dOàW¯tjN¾Œ±M+…B!ãëgÆÍS­üÂE_c ¾ı’©¶*¿ó5]1ã¡9(¡jPRi4©D™>u@íÚºã‘]¥Œ¢ç¨ïB©aâxhìè½Q÷}”©ÎİrMUÒšue‚¶†mÚ‚ToìjÁ”G›İ’“¬º‚‹ucÛVÖ{!ßÔAr­cî+øÌ­%3IHŸİÌĞK}óßìYX—1É¢ŒÏƒ<f?ŠPÚì9¨ix³z
7À{Ï„	¹²™vK®!EDÓ=DSHJûO„buÌQ_¿^’'ä“¨m'(äU©aû·k‚Z6äˆöË©ıfkK)7­Oj6»Ó¬XÛñ[Ÿ2ıv,Ö>FµQ”Õpsü
ÃÈ<Ğİh`¡ÂUl—<ÅêM'—†=3Œ3ËÁX ‹¤¢F¹©Õ i8|b&Ø[£€øZ‰Ì¾ô•ºÅa]Ó … |Šq4¦Í3ƒ<Àpvo¡¼ÔŞô’5cïgï`—ìíüx´to
7±¥òŒçšw‡ãaçìûÎÙøì¼ßïö?.Ta/g˜L0#c°]üĞíwFÇã£Óş‡–ªÈ¤×WæqŒ@ƒG÷I>Ğ‚İ^g™Û—Ù²H0k2Ä´{ì‡º™dšk0èçA'ši…Ëƒ’˜ˆ‰&¦Ø27×İÔ¢Ó×®­šä„®çii2Jèqjàè·è’M·¤Ç!î53È1#E^wı<«êt‘6ê¡x¬ÙÈ„ä¼ßëtG„.*­,#V= ¦a&–vãgaşÑéÚ½î÷èŸwzíñ7Æ‹OgíA\ÆQIååh—æçh2¥ÀC\~,ív¦CAR*¡¡¤¥bøó—åNr)¶ô5Ë²*!àHDRë‘»,5m£TèÒ>Ğ"1ÖÊ‚Hwl›‰PQD¼¬–¡Â¾9ş¿VÑŠk4-4Üd|‰ª7˜Ë%KTí‘ùÉø:ù'Pk$™¬õY‰¿\¤9”u¢¥ñ¥¢-ÂBQq˜Â|†èÄŠ0¢³™Q¡1zlæ`•HÖ§ŠŸÈpÎ`Ö<šJ#6¯ÿåïMËÂ0¢Ù”D>³&äÂ^áj.ŠëCi'Ä åİšpq8gà9–HË·hÚ™èSø7ó@°: }OÓ)}Ç.ÄÿK‡Õ h¶¿Qsé#†­)¤GÎŒ²aœ+ñkJôu+4P¡¯Áµ4ÒI3Í4ÍnL‹àLx—…Pƒ3˜ıí—£Q‘˜zhi^ÚF’y†‰Äê™²ó%4øV	 ù©cNê=ñœ‡˜pÎLÍ´ÅP²œ3ÔiÚ!ºÒÿ°R8œ,’"]pBÛ@){N]Ø¦!ûÉ ¯™ôDÉ»IûÈë˜/(c`&‚àq†á‡èP’¤v8»&AÆdHŠ>Qù€ BWµ¸¨ èQÒ×,ßá“ú-{¼w<NÚƒñètÜ;=j÷à~jò}qİ&(R;~**,õ½ÔUŸ†ŒX˜X„ÿèl&T©;ák¸×l~¤†éòWEd\(2Ì®¢Şß¡İ Ç¢pl´¤e£…#‹Ğ‚öæŒ¯Íeº‰‹‰6;ìô>Ô¸“ğdåê§•‘„¦!Å™ËWëß›Äh¾eÌï1s%[pfBÚñœ¤í:VU584"NÓ¤±,8ºÌÓóÆJé9‚hçš//…·pf¨Ç3	ö"6ÎhÒd¹7‘»üT@5›L¨š7Q7ò*hò¸­©(R?ÒzD˜âBCu¸*Ê0ÅÙ#bo’Vù~ãL{v'¼ÈüÌ·{Òã±8ëm©ÉÙ}1:Ñ,¥rıøfgíyu¶]`½ü}Å‘vû¹#„Ï>?øìÃƒÏ=9øŒcƒgÏ°L£Âe©¡óRõıé¥•hìé©2Ë=
ÃC„ŞİFŒš¼na$æ ]„ª‘Æjî²Ô„ª;Â—q`	I,µÔÌá‘H£VØQå•ª:Ë*>‘=Ô­^*Ğ¯ÆùB+Rê5óñŠqæğæa5„òì™×êÂ³(ëÕèı×ÕŞ¢¬JğÕ‰Ó%OÅ—ÖjTW'Ò]!„Íõ—©Ô‹ò”BÜPÄÙøg½ ®£¾ª2¯NÖkrÒ4¸Ï]s„¢Òê/“İ®?Hùu‡/rÚ0~áÉÛït
çˆ‹Æ1I£µFÊ…)\ÀI¦·iKeº¦Œ†*àÍ2°øùçı53HMıÕ3,^HˆG½N»ÿ'"¿ÿ¾Lìñ ²Iš“0†aöNÄyĞ$´0áá4É°^ğˆúãyş„Æñmûè£î¨×i©”è Ã	¦ŞLİPd7>Ta(ü¦ró&ô4.5_¤„®s4‚Aû¬}2„b"´›ĞD'e!ëÇ”rpñ}ßîw†­R¹4„0ºTÛª¥]3å^cö®¢t©v­é·Xt¯:½ˆÇåØ0uE/&Äéc ¬‘g ^ÚC>"·'3·û—¸=¨ïÁŞ¦$Y`ÿ¾ÊOêP/¨¥T\T¡€};ĞHÀ¹º	øFœ+'Â7RğÍÃ×ˆ~øºÑğu³¢8nĞ*ı]ŞÇáæ^;IèYö¢¤Ìu¼4<]`n­İßÂ_çü"JõÅ_+yDùÄäÌab°á9Iq†µ0)qcIÌrI "1ó(•
¢-ü$?†3ÃZ| ROr|²dî'äú€®=Ñ}Ú¤
D‹3Œ©ÂFÂX¡Vÿ%ıå‚î³y?¹M	Âñ	™¾»r• ³<
Ë	Òûˆ¡ ,gª``Q9•X=¿_şŒûMïcÙ~é2çIŠÑR•R9Zn.}Jò³(­¡cNUè^ûdÀÑUÚ‚€ÇJŠn.uMèF_–n|	]UFÓ“v·Ÿw[¤ğ"Ü,ÍµĞBëbşãÎ‡qwÔ9i©Õªô)U“*ñR]]îìt:·"‡×yøw{º2Äf‡	Ë,""Xr†´ÃK¥¯İ™7td(_IÉç8çƒ+¸8>ıÔ¿z{Ñ±æ]Ñ	t´x¿FèôiN½Ä¢j:S\äÔú
¤§(ÄõqËÿB7ˆ¶)>Fâš7U®„ü–AS”Ôatñ‹ÛĞØŒöÃ%ÏŠÔaêAQn…ë]å{ùÃÄYò×=bÁ•|Œão,øò*²$&w y_Š9Œ€uøë4Q¾òÌ`‰ßåÀ[•¸—¾ù+tÓ”Èx¤ÌiænXÉ7¿}C…~È¾Ås³?ÉU<ß;šjişÍ~cÁ3håÕ¦ı¯¶Úö‰vË¨â~Ù÷ß_ïî®|ÿßxWòş»±»yÿı{´äÙÑ~êÕRMw]¥ğı×¡i¹Q•†Kó£~X@é=eG¥o ÚÍ=6‘^Pí=}UëÄğO¯Â@à¹îpê‰.ñÇÈ0åcñXW‚Í6>é·²ÿ¬\ÿ ûo6›ïrößlîîlìÿwù÷‘‰¾ÇzÆÆX›*I¿¦“í
ÌËöÌ´`šC{ô·óp1˜RÄÄŸ.‡'>æÃí“A¯3Äô–Z<Ü??K!¦£˜üR+úJı-¿Ó†-üûîâª¢Ì•Yãñë?ÌK”‚¸§Zİhò—#üÈQîC¯:åHTî0cÕ%©t¯-º÷¢P&ŞŞ#ÖA…º<ú÷$ûûäÃ`+ Ÿ-°Ù=dFÊ*YŸúªõ· ö;ŸÔÊA»ï S·lúÙ"T=ÔƒzËêwç;ãÄW‡İıvĞ£„~‘ú**ã³Î0K©P00Yè&Ş`	áTg€5îLÊi,êÆŸÙ|%¡££­lZ>+×9•aV†¥Ø”åIó„“Ãÿ&–£°…šB¯Ä
xßEN—¯øª E:%5(êæ÷Ôÿ˜mH¥‹qÃ&‘8‡'ÇµŞäTğ×ûŒ}`Ï›7ôfŸ4•ÚØß×érúı{P?¡X¨ŠëU¬è°×¤'·–\N‘²ƒdîŸÄÜ?áÜ¹íb§˜^Ì_ºøéŠè¡½Fä¶ÉŒkœ›…BÔùæÿ^ĞÉ‰ü
b)Ó -¾RşgN	>,¾Ş-Ç[©,CÇIÖ!Ë5,EårY‡n9º9[†|FÏÊñ®¸Bˆ?âùräÚ§=rEôW®¦ÙàPe!Œ·y™	Š¤ûÕCz·.ÕãÄ´O´‡å‹«Ñ´o…éJÂF©»,ŸôGx| å½ ó;}Z×I^çAgüø^³uŠ4*£ĞØ]»Ÿjt>Óa$é± ôl2´Å&KÜ´MÛ´MÛ´MÛ´MÛ´MÛ´MÛ´MÛ´MÛ´ÿïöiÊšO P  