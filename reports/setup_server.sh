#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="2039543321"
MD5="d27cea38834d3a1dc862e6ea690e8117"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4015"
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
	echo Date of packaging: Thu Mar 31 10:32:42 CEST 2016
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
‹ ªàüVíkSGÒ_µ¿¢³Òù$l	$À¾‹‹²£:!THÄÉ¥ZvGhÃ¾n`è¿_÷ÌìIØIp|UšºíLwÏ£ß=sÍÏŞ¶°½İİ¥¿Í·»[Ù¿q{Ñl½yû¶ùf«µÛz±ÕÜÚyÛ|»/¾B‹‚Pó^há3m9ÜSãÿ§­±°0òÁì¯âkçMk·ÀÿVkù¿µæÿ³·òw›W¦³Ì¥ì“‚ë ó}×”¨3Eö†ãAç¸Û®T¯´€9šÍ@­l©5969êâ˜aú™!…}ò\?„qçôCw<ùñd4nW2_{mËÕ5kæá¼ <<9Í Ó×^û(,E¸Ñğä¤ŸòÏ½öfh{›¶˜Ş$dD\9>ûg#±Î‡ÌG¿ÉB(sïó€s~Nœ¨Ò?šô{?œvN™;ã‹€–yµWy( %+GĞ…X¡a*ÊQ¯Ó?ùĞ6LÍr¯Eñ|Ó	'3fyÕ<(ºÂ»wĞ=y¯œÚ5ÛƒJÊ¨×áÜõBÓu‚K8×]ÛF¡½TMÅŸuÑ’ÏÙoõ:MTƒ¸]#ÿÃ™ u‹®ÚChÚN
MÒ0ÿ–ùÀ÷ºpÅ 
˜UƒMµÈ
9k	 iëZµê%¢„®Ï°Û	ÁĞB-¥T`qJô‰â®Ü€I²ÁÌ½ƒ@÷M‰»‘¯3ùãÄå‰O¨^ #ƒB®‰.¹û€tşÉtXh<	'e:×1´Kgt=(Îˆ]‹'Ô-¦9yhf{á=ò’%(ñ!3Oø^!‰B5)—ÁÓü€nô•9d~°§ÜÍL‹Áù9ªvS…vêpy	û`¸ñ´ £eãf²–¤¥âõh(n©¬/!µtpÿñ¬YiXŠÈíœn)ÙGa{‡“½ÁÑÉÇÉ¨÷ïn{{{wwgg»õ4æQ÷‡³9ÜĞØ#øå+™Ó/;€DO•R©”3®­Õ³@ë‹æ©×~ç¢¯Ğ«Ş|ÉTµ?N‹š®®ƒÎÍœÂ9TÊP·Bh‰4ªI*¿LŸ¹ öİõIW2JÑ€3”w!Ô0u}T`´È(ûòTç¦¶¡*YÉ…¦2Em9‚DoâiáŒ[w³oÈğÕ=È»´ùª±Mr«ÆıˆïGÊ ™Ë	×>s{ÁL2`×6ZŞI`ş—=	ë1f Yä€ñy°¡Ïœ§AJ³Ÿ‚šE×Ë¨p¼óÍq@˜’)³µ2·hˆÉË™è2˜ÜLbéHµ&P'õåKxìû‹›)
YUjeØüóš –w#¢ı~jÚÚ2ÂMë“’Ín5+‘vüÖgL¿™ˆµOP@äE*\¿Cu/îŸÃe¢•<hêç99'ƒ†=6z(DU,ÔE˜Ğ 03€ú2<Rìm "ÁK%VúÊwê8\‡õLƒÄA€òÈ/$ş•¶ÎÒÿ©‰2˜İYd„Ï´3¤¼`ÅØûÙ;#Ø;;;/Ü™ÂÕk!/“¹z£É¨{úS÷trz6ôæªĞŠçÓ	$˜‘ÓŒ¿X'~îºã£ÉáÉà}[Ud(‰@MÂ{ïQ,Ğ†÷½~w‘É—Ñ¯Ò$´\gDº‘a–e]0ìA§šiE>+‚›èM™e¬­{™Ef ]Y94'=ß]ÃÌt”Ğ“°ÀÕoĞ¤›nKkŸ@ÜifX8ŒyİŠGÕ¤zzÙ¸‡|±æà!¤ gƒ~ï¸7î¦Gà¡ĞÊ´`9Ğ#Ö Qfji×Aæ_İî°ÓïıÔ…ÁÉQ·ßùÿ¢¯øxÚ&i¥H~våáUf®”¸{+emCzœY7P€”BÃYh(%©©èú‚ÅD¹‰\ˆ-mÍ¢„Ò8^Ôºç&SGÇEy´ÔHô³2ÁÑ]ÇaÂM”//eh…°ïÿ[)hå’^:¾@ÔŒkŒãRˆ¢vÏ‚t|ÿS¨œL×ú$GË_ÎÒÊ*Ö’øRÖ–a®¨Š¨ŠğÊÍXÆTÑ*£Ïlc¬”³eğ¼²ÂO#æñL²±y>/·xgZºÍ¡ :˜5%îòŒUó½˜jH;%†(æÖ„‰Ã9CßµDH¾AÓÚZ¨Ïà¿ÌwÁlª" }_Ó)tÇ.Äÿ[
‡™ `æQré#m($‡®M‘0N„™õùº(ĞW÷àYšN¡¤†Qf‚F’N‹¿b×¦ğ‡ep§¼ËBhÀ/nÄ‰Ì¹wËÑ(ÁM=²4?«#é<HHÃ0bùLùyS|«€ç©cNâ=õ]›COM?9?LÍtÄ³üd¨Ót"4¥ş°28œ,’"Yp#Ç@.ûèN]MÃã'K€¶Ö6Ci	ˆ’÷’&ğ¬“sA37ˆ+0ŸNˆª‹Ä=p"ûŠ™!.¢û@ZDå=‚YÁ£ÅE…ÉD÷’¾f.Ÿ„ĞoØıëpÜNÆ'“şÉa§w3“ï‹Ë6A‘Øñò¦<`)ï\é¥¬4,`ÄÂÄ"‚û d¶¥Ş”¯áNsx‰Ã%<_¡±6p¦hx`NåşìO,Ş	ÇF}AZrQ1jPz¼%äkó˜nâbâÍºı÷®ÃÄ<™µÙ""Ó4¤h{|µÁIÍ·ŒQâF®¤®-¸ÌIÒ®cFÕ€#A#>iš4áG—ñbvŞD(}×%Gï\D9RX×F9¶M$,±qF3¼—*Ë­‰Ü}l§BÊçØtJ™¼‰²iUA•ÇmÍÜ(D–òø‘Ö#Ü7ª¨ËEQº)nÈîÁ{“ô0ÃÂÂ9ÀÌ½c·ÂŠlÀo|û‰%=šˆÚm[M‹ğå¸BYÉÄúÉM\B^XÎ'¡«Ğ‹káKJÔyì§ÊŸ];øìÂÁçV>£dğd½€}b:äs±‹J“r«‹J‹’°‹Ê6ÔuØ‚ƒü½ÃSAi¾[™.yƒ¢æŠ="ôY’ÇÙR&S˜/ÊÒ„ÇoZ¼Œs^'||+Äóñ,Ïvxõi9„òdjy²X–9f\Éş#Ù²H„ã¤yy¨sÁƒçƒƒ…ÙeÂ)c—A>óÔúyrë²¬*ˆ;‚$~şŒJI0#AUe¼]Ÿ®–$<GÓà6rEÁC¥µ_¤{]]öøcÅg©ŒÆ'ÃßY%ûJ3W\ôMˆí¬PÎK9 ²8S…òŒ•*]ÆCµ}ğílmu)£ˆúü™˜wØïvß0óø½›°îUb¤8ÿ‘âA-V#¡£ü]ˆºÍ4²00á4I¡±Œüá¬ß RüĞ9ü×¸7îwÛ*$hhÂ™ïF×3/QH u	»ƒ!×Ô¼|3B-^£—)ğêaØ9í œ2í:2Ñ8Yxô
8û~êôÏº£v¥Zy„Ğ§Ôİ›º¥]1ù]a”­"Ktñu¥é7¡Zt÷ù,zŒË±Qæj\LˆÓ'@˜ËÚ ^8#>"·'Ë„¹[õÜ4wawc¬±OåÙ~š%µ’ñ†*”°oZ)87ßÊ‚sáDøV~ûà%¢¼l¡|¹]S\/lWş)ïÌğÚ–¸œEO8ª\Æ+âLçkw7ğ÷~Ù•æüïµ"¢|Óñf‹0ÑÉğ8Š¸hcÎ
#r@\YRµ\à€ˆÍÜ;e|g?É†áÌ°Òôîsöp£7%Mæöp
¿ı¶t5‰¦Ó!Q Z(ÜvN(FÂ˜IÖÿ#måœîœyq%Ç'dúBìvìÀU‚Îpï+'Èî#‚ªœ©†YxãL4õô~¥3ø÷›İÇ¢ıÒ•Ë£Ğ¢­*•j¼ÜlÔ$‰
s‡3TÔP„né•M>Èº@ÅÅ-xü¨eèfãÕİ8ÎËÓÍ…·éªÒ›wzƒ¢Ù"îfaŒ…ÚóußOzãîq[­×¥M©›”1Wšêbc§SÕÜŠ^÷Óç˜»ÄÒ“"3'’8HX.`ÁÔ0¢^(íÖ¼¦Ò|$ŸÁœŸ/áüèäãàòõy×	™I™¼4´ø Aèô_îM%¾¹là¼ Ù—â=>ù .‘›Yş-!ÚÚmñ1×Å¼©r1dº‚z”y¤âûY4Ş†ÆlÚ^—¾èQG™·<Y¸%Öw™ùåïoR{Éáˆ×Šn?…àË«ÉLThİ>Í)†1ÖåÃDÖÊƒ€¦—oÔ’^úæ-ĞRS,ã“<g¥˜[b¥HL\&üù¡¥÷¯Q‹—^ßÈ9ß;jkåáû½nı«¾ÿ=Ön%~Ïûş÷ÍÎÎÒ÷ß­·ÍâûßæöúıïWiéK•½ÌC—†îyJé{é‰®"Ó2
£*Wşy•wä¬+ßC½Wx£ ïI ŞüDêÖ±œ\ıŠF)8ô¼ÑÌ]âÇØ0åŸ±d¬'ÁlåÅºı9úŸçë_ ÿÛÍ­‚şoooï®õÿ«¼ÿUô†×®PÆÆì@IûƒĞ0İ|WhÚ,ßcká¬€vlá0¥Œq(İ5º»ŒÍ:ÇÃ~w„¡¶dtpv<‘#ş¸C1ùUÆ½ôcı5¿	…ü}{~YS”Y®ëòK#‘ö•’¸İZİƒñûş1~ä‡ÈÓ;@95Â[tI*ÛëˆîİØ“‰¦¡Qy©„şï{{dÂ`#¤Ûà°;ÈTUR>õ5Ô›¯At?ªµı"öÀÅ3İpèß6¡úfÔ[U<ûĞl!¾:ê}túİÀh/¤[Wƒ¶R8\×«ÙqêÇŸX\-¥££*„lY«69•Ûª¹qüßÔr1ãÜ@æĞõ³ ÊûÎÒsÉâFôR$f£dZÜÍÔÔÿ˜cH>Çƒ¸‡P“HMêŸº>4“SÁ?ïr"‰=¯^ÑÃjb6Ê‘±·§Ó-â»w ~Ä“¦Df$îÁ0Ç^“şáp8¹µ/°ä‚pŠŒè¥sÿ*æşç.l;Åôbş’8 ó_/é%ªHLn“4§ÁO³TŠ;_½âßsúGDq	ãè¥Æ_)ÿYàë{âÅ›j²•Ú"tœd²\ÃBTÎ—UÈ	ã£›ö"äSº®&»â!~$óÈu|_»ç‚,]Ív‹CU3^y&(’Ø×èq±ÅËë~ñ„Yh}W%Ä£ş²xN5}VM–Š‘T÷“ÎxÊ/Ù'Åˆ„('ÃØİ¸›iT-ˆ-’ôYùéÖ|Š­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº}ƒí×|Ü P  