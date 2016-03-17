#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3074085127"
MD5="02e42b22f7fe76b542194b73b17ee47b"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3949"
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
	echo Date of packaging: Thu Mar 17 14:54:39 CET 2016
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
‹ ·êVíkSG’¯Ú_ÑYt„-ÄW`qQ@&ª¡B"N(Õ²;BkV»{ûà¬ÿ~İ3³O$}ÆñUi*1Ú™î™~÷ÌT×W^¼m`{»½Mko·7Ò£¶R«ÿô¶¾½¹¹µùve£¶±õv{¶W¾Aı@ó V4Ûğ˜6î©ñÿÓV]÷YºUüwÉ¿¾ùvûmNşõz­¾Kù¿x[ıaıÒ´×ı±¢¬»3pl`çx¾‚š¦(ıı“voĞmµÅÒ¥æ3[›0P‹jYÚ'8f˜^jHaw®ã0h¶Ã_ûƒFñ!õµÓ°]³ÆLsÀ½ã“0}í4ş‰Ê’‡ë÷;	 ÿÜi¬w}bø¦;Wú½Îi_¬ó!õ…À¡ï­ó…Šk…ş”ÀÛ½,à”ó‰U:ÃNû—“æÉŸÃ^sğkĞ2/wŠ9 Nt&x`˜ŠrĞnv†©YÎ•¢(®gÚÁpÌ,·T†E×x÷ZÇï•S_»b;PL¤•
œ9n`:¶gº3™ ¶^(
ˆ&‡¢ÏŠhñçøS¥B•!jW(ø`lú@İ¢+†vš$@“šøÌ»apÑ\2}f@É`#-´.»rLÃG¾ë8V9Cƒz uˆ(øã1ì¶0´@K(åd›½A¢¸†KÇg’¬?vnÁ×=ÓEâNèéL~E8Ñ_É±<‡*90òdšè’»÷™ï#£#ğ;Ófñ$8rÊ´¯"h1–Ìè¸Ÿ»fO¨[L³³Ğlâ÷(K£DLf:rø^!BûX]Wó|úÄ _hÅóüåvlZÎÎĞ¦k*4PYƒ‹ØÃ‰¦]‚7ãµÄ-Q¯GCQKt}.y¦¹ƒ»»gMkÃ\DîàpsÁÈ1
§³ß~hw?ûí·››ÛÛ[[›õ§1Z¿œfp/dàç¯tl>±*…B!ãUë‹gúgÍS)á¢/1œ^ÎTkåÿó5]1£š9‚3(®BÅ
 ¤Òh&‰ş2}ì€Ú¶uÇ#[IENQß…RÃÈñĞ€Ñ#£îû(S»Úªª¤5jÊ}<¶QhsR½¡«cîİlrM¯âB6–M­S¨X4î…|?RÉ]¹ıó™3f’>»š çúæ_ìIX—1É¢ŒçÁ³ŸE(mòÔ8¼š¿@…à­gŒÂˆ\ÙD»&w‹˜¢œiƒ¢€)ÌÄ>‘Xª]3:ä¨¯^Au=ù&—ImÖ¿^Ô²1B´/§öÕÖ–Ò\ZŸT[v£Y±*ã7ÏlÚ½iFÉë`ÏCäRè"–W)	ô¡Òƒ@waï‘&coµ^)‘ePgÀ¡ÆsX×4Hf”Ï@Î;‚´f¨_gÅ¡ÌX	ö>{Å;cÅ§ƒG+¾¨ÖafFF÷şf­û£İm†ûÇİ÷U‘9 ¯<ÄîY<îİG¡´ïÛÖ,)“G‘oU¥i9öĞu«4-ªV ×>Èƒ4Ó
=–%)MÌ8eªª»©E¦¯]Z4;I§\Ï	³´d”Ğã¨êè×hqÉ¦ÒYÆ·šä˜‘"¯»~U5ªÃ1HE=Ê4™€œv;í£ö •°ÀeŞPfÕó‰F õÓ0#K»ò³0¿µZ½f§ı{ºÇ­NóOü‹ÅÔ‡“f/®j¨Âğr´‹§ıÖÉT)ğèK[wÂÎ´£ÍAJ¥á"4”‚ bäğgåÎk&¶ô³8eß°/‚uÏ+/ÛÁº´´HS²>ĞÛfÂ¯"^VËĞ`ßş¿PÑVhZh¸ÉøU3®0J f¨Ú=ó“ñEòO H2Yë“]ı|‘æP‰–¼üçŠv¦ŠªˆÓ~âÑG'¶
*­e2‚Æè±‰ƒ)J"YŸ
`~"Á9ƒ	ç`,EŒØ¼–[¼5-ô±fSşøÌ‘wxÁ§¹(^,­4¤C”²jÂÅáœçX"£]£i'Z á/æ9€`*Â‘¾§é”ùbâÿ#ÃD°pÆ¿¨¹ôÃVRÏ},¬Q­q",L/)GÖ­Ğ@…¾¼×ÒtÊÄ4LÒb4ÒtZü%»2m‡‘ˆ3â]@ştBNÌ`ö}´\Fùy`ê¡¥yiIæABü°`¦ì<û	¾U@~ê˜À’z<gÂ¡G¦ç‡3S3m±'”,çušvˆ®4ÄV
‡“ER¤Nh(eÃ	¡ëÛ4d?yôµ3€H y— ibyóeÌDÜ ®À0<âÊ‘ôÀ'—$È˜IÃÒ"*ïDè
²ÄİKúšå;|B¿f÷·gÀQ³7;ÇûÍÜM¾/®ÛEjÇ%ƒ¥¾s£—ºêÓ°€‹ğïı€M„*µG|·šÍO˜0mBş
£ˆ¬EC†ÙÔû4°+äX´ö‚´l”¢PbdZPÂŞœòµ¹L7q1Ñfû­Îû*·a,úüô"’Ğ4¤8qùjı[“Í·ŒyŞ-šdÎDH;“´]Ç‚¤
‚FÄiš4–GGpUKÍ+¥ç8¢k¾8ÍŞÂ™ OL$,Ø‹Ø8£ÜK“åŞDî>òS•Cl4¢BØDİ4È« Éã¶ÆN HyşHëaŠ;
MÔáª(Ãwd÷`ˆ½IzX ûA0vnÙğ"kğ‰o?ö¤CqôÙP“ÃëÕè€¯˜ÊÖã«èĞxæ¹mö”vÖÁí3ëçgÏÏ®œŸ[6?£f~²`fwL‡l=t^¬Q}s^¬S!t^Ü„Š°·‡¿·x™%p=Õ%ïÔÌi‡H^æ²:zHåúÓY•’ˆÙUA+…—
¯óñD”ÎcEª´`>DÑÇÇ€×wó!”'i:‹]tf»¨ôUeTÎÏ:Îy»·7³Ğ¡²2‘Ğ<!0^§~ÍBUnYTİâ ;Îb:$eReV[-–6²È4¸'ZPğ«´¬ódóËş<½é{_xbóNoq£4$6°S9bá€S¸ î–àšbH±D÷QÑPy¼I¶¼€ºT¡ÿ‰úK‚ìwZÍîw,<~Á#¼h‰)Xã=2(G¦ ,¡Ÿ½ôqÂ1
-áœæÅái¾C£ø¥¹ÿÛ =è´* +FgŒ='¼»¡ˆö>T /|&'#ó*ô4.5_»J)Jk ½æIó¨µy,´«Ğbe†¬Ræâû½Ù9mõÅRñAB—_q®+–vÉ,”Wx‰ù¨Š,ĞË¥¦_f`Ñ%ÛC¼èi<.Çú©;X1!NaÕ7õÜîó¹=y –¹¾=ÇíAm¶70Ösdµ‡ı;*¯‹kP+¨ÅT°R¡€}POÀ¹º	øzœ+'Â×Sğ›{¯}ïUCÔ«Í²â¸A£ø/y9ƒXˆoÀEt73ë‘@‰ëxñAğtŠÙ¢v{?>ğ[E(Ö¦?–óˆòÕÀ˜uÂ™
ÏWHŠ¬î OA„Kb–c¦_å‚ÌËIÌ<¢7úøI>g†…®w—‹‡;½Y2÷‡#øôiè]§Mª@´P¸ïRÍˆ„±æªüGúÊ)]nòş2âJãô1EîÊ¬lº›GOI<½5*ÉYÊìE¸Gßşü½Ê@ğ½í5½‡Y{Å*íş°ß:ù½u2<9ívÛİÃ†ªKÑRSÜŠV,Üp”ŠĞ†ªsCÏ82àh|*-_ÀãG9E7µ²,İ(ıÊÒMƒÏ ]%5Ûİ¼»"Eaf–jcè.ÖÄü­÷Ãö uÔP+éK*&Õ”Åš:ÛÉét®lE®u÷7{¸#2À#f‡	ËL#"Xz…´Ãs¥«İ˜Wtø%Ÿ¿Èwg§½8;8şĞ½xsÖ²æ]P­+İ"-Ş¯:ıŸy­D¥a&I?Ëiõ$x4dÊq‰Ü½ò_èÑÇnŠ¸äM•‹!—åGĞıÔãµİ¢Ó646¡íÅpÉ“µŸz,’†›ãuç¹]şÀ#ñ“ü•‡Xp9Şø];_^YVzÂæv!ïF1}°y$ªBÔ Ìp¹x­÷Ò7¿ÍGM9ŒGúœÖbî•<1qÜşõS*ŸC~Š+}'·¶|ïh­Å‡Ÿwê¸õï?´kF¥ÕË¾ÿüikkîûß:åŞÖ6·—ï?¿EKŞ4ì¤Ş;Tu×U
?Ëxqš–‘Ui¸ø°ÿÇS(¾ãõg¨´s·åò¼*ÇO$¡bşñåGtş¾ëöÇè?†)~L”•e{Á÷ßY¹şö¿YÛÈÛ?ş­-íÿ›¼ÿLô&Á0ÆêxOIúıÀ0lW`NX¶g¢ãÚ½¿‡‹Á”UÌéÎ¬ß:<ju1ƒjõ:­>&DØâÑîéÑPBôù#ÅäWR˜ÒÌ@ô7üFÖğ÷ÍÙEYyP
4d9»Ï/?0‘ÙU
â–hAtŸÃï­ø‘¢`IÏÁäHTn0ÅÑ%©t¯-º·£H&Ş=æÎ…z<zN¾³3ğƒµ€şm€Ín!3RRÉøÔ7P©½µÛú –wóØ]yºfÓ¿ B•=Í0¨·¤şzzØn ¾Úov›n`NĞí¡A[)në¥ô8õGãO,®œĞÑÑÖ-Ÿ•j_DN`e6„édfCÿYÖ„k(ºFDyßYN{.øBœ^<Db”B‹ºù0õ¿fRÎÑ î!Ğ$RúGÇÍäTğÏ»ŒJbÏë×ô¾–„zdììètöî¨ÓTnôÅmfİØkÒ?'·v–\N‘R½dîbî8wn»Ø)¦óƒÎ>^Ğ‹ 4‘ˆÜ:YN•s³Pˆ:_¿æßSúGr"¿‚Xpôâ`¯”ÿÌÉõ=Éâ§­R¼•ò,tœd²\ÃLT.—EÈ±àf£›“YÈ'tÏYŠwÅBüˆçË‘kzvÏÑŸ»šÍ:‡*	a¼ÉËLP$µ¯ìÑS©³—!Öı¢	²°4ú.IˆGıñ”NUôq)^*fY­;ñÂ^±;Õˆ”(£ÃØ]½ktb™S[$é± ôl²­é2?[¶e[¶e[¶e[¶e[¶e[¶e[¶e[¶e[¶e[¶e[¶eûÎÚ˜†õp P  