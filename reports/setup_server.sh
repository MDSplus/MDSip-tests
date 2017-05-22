#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="2397337173"
MD5="e158eb80582e92281ee94622327bc41a"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4549"
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
	echo Date of packaging: Mon May 22 18:15:17 CEST 2017
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
‹ •#Yí\ysÛ6Ï¿â§@imVr"Ù’ãdÇ‰¼Um%Õ¬e7íÚEBc^%Hëè»ï{ xˆ–d²Ûîß´	üğp¼À˜æÆ‹g§M wÛÛøÛz·½™şèEk«ÕÚ|»ù®İ\kóÍöÛdûÅ@!4ŸšcøT[{*ÿ”šŒ¡×dÓ?Kş[Û›o²òo·¶ß½ ›¥üŸÖ¾Û›Î›*Ê¡wf@\‡Pßw}¦€fU”áŞIpzÔ=ìuªµ±Æ¨£Ù”¨ÕMµ.óFûıÈ3L?•¥Ğ;ÏõrÚ=ùÔ;ıx<<íTRo;ËÕ5kê²`–OR`|Ûéü”%‹ İél¶·aÌôFEæÊáşppp6í|H½8dşoñ¬ÍŞÌg|œ8Ó¨û£ƒş'İ“_FƒîéY¼ewªPÜ€.,¦¢ì÷»ÇŸ:†©Yî•¢(o:ÁhJ-¯V'Š®äÃÒ;ş¨œ1íŠîj"#Òhs×L×a—ä\wmt÷RQˆ ™½6Å¯Ó¯VT']S“LI1Ú4v'A£Ò0êßPŸğ~.S2jšA'Zh\’õ˜Ìs]«>ÇShr`ëSHvbh–pÊH:azL¡c—QÉ–Mİ[Âtßô€¹ú:•oQ™èWXv„ú€Ì‘H’½g”1è~g:40„ÃH™ÎU„yI®G²5BÒâ
u‹jÎ<šÚ^p²¤q‘h©#|½
MBuM($æ+
jXÖÚñ4ŸQ¢Û>ıÔg;ÊíÔ´(9?oĞRI§Cëäò’¼'†ÕCtp&"ßŒÛS¢Š²"Jìb)}ÚÒÌ÷ï×šÖœ¥¹kt‰Ä-…¡Kîjo0úÜ?Ú?ş<öÿİëlmmo¿y³Õ~ºä~ï‡³Ose?¤ğË[:5'Å ¶i¥R©ÌùãöêZH»P=úolô&âë"U­×?/Ê4]1\æCsBÎIu4¬€´ª4˜T¢¿TŸºDí;ºë£]¥Œ¢IÎ@ß…R“‰ëƒ±ƒ÷İg S»å¦ª¤5—´”	ØĞ$t8UoäiÁ”Ï ³¯ÑI6<2?ÎVåmà´²*ßy¤¢kq_Ákî,¨I"½²ÁK˜ùú$Ö£Ô ¶ #6ğ©ó4Pšıj^-i`
äOîfcêÚtC,7 '¡Î#MÏ€ú¹ ÔĞZyí¼À­¼@;/ğ&/ğj0…4è¯áÈ×ns±5&V°©»íä‡Ì/¦ùÁŒyÀwvğ$?XËÏv^¢ 8È¦ÆU~°}[@"î¤@›=Z<)Ğ¦EÀ7À^ü¥:,¢¡EºxW ‹;ÉÖu£ gZ@†&3Y~ô•g·‹^‘Û.+ĞêIm¢ÌÍvÆÆÃñ
¸%ËÜ* D_ÿ¦bQøŠşÖ7ÊWd‚{#[»Æ½ì¬p‹m:DaÅèó2@QQtÄ‹¾|¹ ğ2æFR·iHkdãÛ‘à6¿‡ôÛ¹}³¶¥VËØ>¹T¦7š/Ÿá]ŸRız$Ú>‚¯Ò@Qñõıw°/}t/Ê˜©ä2^èó˜M0›[:ã	RlØ¸’LP‡ºˆR41ØÅHc@€5Ù}´î†Ô&î°_*Ñ>¢úº âXÏ4P!”×€[Íx{§n)&°£Ÿï[hÏÕ7`½ Íš»oˆ]Ğ·³ıÓ…}Søx¡<ãºúÃÑ°wòSïdtrvtÔ?ú4S…e<Ÿ]˜4qÎ:şd»ø¹Ô;İí}ì¨ŠŒ¢1åA©€dFÁ½÷(²Ğ!û=r±`)o"V…¢\\gÄB]§Œ¥¹`À—úû1f¢™VèÓ,E‚fêà E`O÷°0³jckï¸JÅóİÀÕ]+•Œ*ÌÕ¯ÁÔ“.uäÎP©Üjfé#rÒ=–íz(`^Á-ºæ@Ÿ’¼³£ƒşaÿ´=ò@ßdHqAî£Q¹C9±´+6Ÿù¯^oĞ=èÿÔ#GÇû½ƒî/ğÎıóIw (•Å6* ²9ÍAC\?xœ™¶a˜´¯Îb¤pùÀv[Âû±Åå¥?X¤9<pHöÄtgİs»6H¦’ĞÃ^€ÙÀ„(Ã ºë8Tøó5(7¯à* íş—´XQÖ’˜á#…	/É_ 8Æ•z#èÏ=eIş*'¨U‚Lû´@“†çl¦ÌJ£3/.à52STE¤ğÃ!ø›5rŠçrñææSÛ…%Q"_†Ñ~~ÃÇ‡5¡„4”æ±ÙÍ[Ó²ÀãkĞ`GmMĞÛº<º­y dÏ75à0sÓ„k‚:ßµDHn«µµ@Ÿ’ÿPß% ³ñÄøûš¡;H‚òKp®õ8ü‚şâKŒm*¨¤{®‘0¨HsğÄtt+„-,ßÏÒt\ùi°(Œ‹¡¾cãÇôÊS×q'<É3h’_Ü33¨sõš£a€10õĞÒü´¥$õ #æüå5Í×³—ğà]E Œ§N©J>ñ]›£'¦Ï^†¦f:¢O Y>2˜h:!øÌ¬TÎX¡.¸¡c€”}˜°¸›Ãş |«mÒ `ï!+f0Öñ¸€Œ	5„°‡ÂI”qB{Œ‚ŒÙ aJ ^Èå#@„®ÀĞB£‚¸¢{É_³˜Ë+Áâ×ôşÖõrØŒNGÇ{İr;5y¿¸n#
ÕŸˆÊ–úÎM_ê*Ãl`÷, ¶P¥ş„·áVsøq¬l`|…QDÖÀ…¢Á€9Ğû0°+±¨'¼4Øğr@ŠB‰aˆÀ‚’áÍ!o›GuuvØ;øØä6ŒÂ“Qk–>P‚‚(48Úo-»5q y—aAw‹L´×ÒëDm×aÔ$û‚G4ÒXi,^\.íÒõÆJé».NQÏ5&.…·pmĞcÛÆbx¡4Ôh÷Òd¹7‘½üT€Û/:™`$ßİ4Ğ«€ÉC·¦n€HùRÛ#&+î(40Q—«¢œ¬¸#»'†è›äGïLdÆLİ[z#¼È:ùÊ»{Òı‘8çí¨É¹ıZtšYM-Ëã[+Ïªç÷Œ««Ÿ/9Î/=>ÈNÊÒÃƒ¥ÈGG«‘©ƒƒ¥ÀÔ±Á2Lrhğ¡ä:2È{^÷° ïIA¾c‚|gùòä;Èy.ÿP ÿ‰@‘ã€ügùòŸä?ÈÿÏüÏùÏöÏóÏğÏíÏêÏçÏäÏáÏŞ/Û/ØÏÕÏÒÏÏÏÌÏÉ/ÆÏÃ/)Î½/ºÏ·Ï´Ï±Ï®Ï«Ï¨/¥7'|­B...ªmÜ
«ŒM/Ô(4Jï¨
ä’öî.Ç¿Ùà¥šòî$µğZP¦„Ç‘-,*ªhLùÃièd“d8É-Ş’
&&®
ÓCD°dI¬›¿«<z¡VRqÀÙ…ªÂÆÿqVÄ
š‚íc©­ıj"L°„A´¢å,–µÇvm× ¯î–#”'¯»,¯ÉÈrtî÷EÉE <
–¯œğ«>»»‹šË#à‰,Ceà!õç‰©¯Éóq91Éå:%ë ½Ve¯1Y­a0’¦Á·\+;TlıEÒÛÕG¿ïXàYÎ†§ÇƒßxFö—¹âñ¥ÑY!
å\ˆ”gä%S#×¸Ñ®Öğ†r”UO|{['_¿î¬¨Ajêï®aöLBÜ;èuşÂBäWÅDPCŠáñ “4'aÃùëÀDãLBËº<Ñ°ñ0ùÓYŸüã‡îŞ¿Nû§½Šqp8ÁÔwÃ«©Šà#2şGw‰yú„š½É¿†ñœŞŞ)tOº‡C²–í*4ÁIY0ô#\±pñıÔ=8ë;ÕZõA0‚Ù¥á^7,mLa*†cÛT`ïÓ5ı:0¯T?ÄÅù2o˜º/*„êcĞÄ]Q/œ!Ï‘İ“…sû/ {¤µM¶7aéÂ«HßQù9B‹´*j55/ª¤i›¤À¹º	|;çÊ	øv
¿µûŠï¾lÃlør«®¸^Ğ©şS^Å…X­m&SÏ¢Ij\Ç«bLgä+Ñn¯ÉßørRmÍş^Ï”_—<Q²%a²áË”¢­Á<9Ä‰ˆKb–&"3Ÿ¥R“h^ÑAÍd¥~/–«èø&hÉÜ'NĞõ¼ñîÓAU@^81#d„v`ìÎş*ıå¯²ótt›ÂËca|ƒÒh"W=ŸÁgaYAº1ŠÔdMu˜˜Å¬œZX=İ_9!üû›îÇ¢şâµ‹GKŒªTkQs3Ë§d}-kğ¬SºÁ}æà`„*vAàá¥â›Yº&|£ß<ß4|_UÎ¦‡İşQÖm¡Â‹éfáZ,´%êßï}õO{‡µÑ>¥ab ¾ÚR;;Oİ­Èáõîò¸»ØÓ¢!R'”e€±lÀ,bbC.öğB9ÒnÌ+<1”HÉ/qÎÏ—ä|ÿøóÑåëóPÿ¤{ÄÆ³&Çÿ«¸Â°0˜>·)8Ï¨õ%I
=^òLh÷±ü	Ü 8Ú-ñr*nŒqReKĞo±=L}›¤£+Zà¹ÚØ·—|Q¤Sß¥qK\ï2ßË¿éIœ%ÿ°G4¸ãøç¼yu¹;&÷d})¬aÖå¦‰İ-_Ù²Àïrğz=NÅwş¸i\Èø¨ÌiænXÉ2×¾ı:Ã!?÷_šıE.Íñ¾ƒ©V¾ßiÏø
ZyQÒÿ557µkŠÛîçışûí›7K¿ÿo¿k=úş»õ¶üşû ä–ğNê’qS÷<¥ò½œÿÇ¡i™\³«{?ÿ<#Õ¸Dª~OıÌİPyé…4MÖ¡ÁÇ_`6`{7œú"I<œ¦|ğ)óúf—é[Ùÿ¼\ÿûßÚÚz—±Hj—öÿ‡üû‘‰~€M+Œ±9İU’t¦;Ÿ˜6O±µ`š)vÏ6²¸¦¬Áê/{Ÿ{G°(îzCXã"ÅÙGg‡#	òË¸ŠÉ/fÁv`U©¿æ÷ÚÈ:<ßœ_Öñ¦0fY®ëíñ+@°8}¯TÄ]%‚-Â[Müç)¼Ìgá?Â9¨ÜÀ²U—¬Ò©HŞ¦2ñ½pàßÃf¨R—‡ÿÄÎú0²àßqè-™Ë©©h}êkÒh½&êQï³ZŸ-}äÂ ®;ø·CQcW3L­©?}ê6¡¼:ì:ê`ñhU¿„Ik—ÑIo8Ï©R1`Åàm<ƒ&ŒS‰-	nÜ™ÔÒ¥0=Ê¢óõ„¶ĞAh1Zkı&v¢ÔÜ€ÁdnÀRÃ4?& Îş›X®uĞ¼Ù(ZÀÓÎ3º|É[í†x9Ò)©AQ2?¬Àô×„:†Tº(:h²á‰ës­79øù0gòê~³šJmììèxAíÃ¢~±àfv(nXÁ¶RMüÃqP¹õ^”’‚*RvÔıEÔıêÎtEõ¢şŠ ó/—xñì5b·fÜä£Y©D‰¯^ñ÷ş‘#‘mA,å}¼¼Î[Ê3JğeñöM-îJ}Qq¨dUaÙ†…E¹\V·¸¸i/*|‚Wkq¯¸Bˆ‡¸¾»®ïk÷\ÙÒÖlµ9ª&„ñ:+3Áu¿±‹Ÿ™Iõ84CínqcDë_“¨Ú×Ât'a£˜\“ÀGéQ9òaOŸÖâvÃ"¯w§Sƒ!/é:…5§ĞÜ¼j$Ïè0°ôiúÚ¬\%–TRI%•TRI%•TRI%•TRI%•TRI%•TRI%•TRI%•TRI%•TRI%•TRI%•ôÿEÿq³5 x  