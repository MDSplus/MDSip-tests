#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1256408070"
MD5="8bcf90de36590ac168f1da76eb564323"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4021"
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
	echo Date of packaging: Thu Mar 31 11:00:30 CEST 2016
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
‹ .çüVíkSGÒ_µ¿¢³Òù$l	$À¾‹‹²£Š*$âä€R-»#´a_·0!úï×=3ûDv_•¦.F;ÓİóèwÏ\cóÅ³·-lowwéoóíîVöoÜ^4[oŞ¾m¾ÙŞÙ}ób«¹µ»Õz»/ş‚¡æ¼ĞÃgÚr¸§ÆÿO[c3`aä5‚ÙßÅÿÖÎ›fÿ­Vsël­ùÿì­üÍæ•él3E)ûd†à:À|ßõ%êLQF‡§½áxĞ9î¶+Õ+-`f3P+[jMMz§8f˜~fHaŸ<×aÜ9ıĞO¾?Û•‡Ì×^ÛruÍš¹A8/ ON3Àôµ×ş
Kn4<9é§€üs¯½ÚŞ¦m¦7	WFÃşÙH¬ó!ó…ÀQàoò…ŠgEÁœÀ{Ã<àœŸ'ªô&ıŞw§ÓŸ'ÃÎøû" e^íU
@ÉÊt!Vh˜ŠrÔëôO>´S³ÜkEQ<ßtÂÉŒY^µŠ®…ğîtOŞ+gvÍö ’2êu8w½ĞtàÎu×¶Qh/D“Cñg]´äsö[½NÕ n×Èÿpf@İ¢+öš¶“B“´Ì¿e>ğ}†.\1ˆf@Õ`S-²BÎÂZB#@çºV-Gƒz E‰(¡ë3ìvB0´PK)Xœ½E¢¸†+7`’l0sï Ğ}ÓCânäëL~Å8ñ_ybÅªÀÈ`„k¢Kî>`A€ƒ2O‚ãI™Îu-ÆÒ]Š3b×â	u‹iNšÙ^x¼d	J|ÈLÇ¾WH¢PMÊeğ4?` ÛıBe™ì)w3Óbp~ªİT¡İ†ú\^Â>n<-èhÄ¸™¬%i©x=Š[*ëKAÈ@-Üß<kV–"r;ç‚„[
FöQØÃáäcoptòq2êı§ÛŞŞŞİİÙÙn=yÔıîìC7ô#ö~ùJgæôË ÑS¥T*åŒkkõ,Ğú¢yêµß¹è+ôª7_2ÕFíÓb¦+†ë s3§p•2Ô­š@"j’Ê/Óg.¨=Gw}Ò•ŒR4àå]5L]-2Ê~€<Õ¹©m¨JVr¡©LÑÆc›F‡ Ñ›xZ8ãÖÁì2|uò.m¾jl“\Åªq?âû‘2HærÂõŸÏÜ^0“„Øµ–w˜¿²'a=Æ$‹0>6ô™ó4(BiöSP³èzù®€w¾2S2e¶vCæ1y9Ó=B“›Il"©vÃê„£¾|	}ÑÑCc3E!«J­›^ÔònD´ßOíO[[F¸i}R²Ù­f%ÒßúŒé7±ö	
¨ƒÜ H…«ã7(Â¡îÅıs¸L´’M½á<'çdĞ°ÇF/…¨Š…ºfPR†ƒGJ‚½T$x©ÄJ_ùF] ‡kâ°i8P>ù…Ä¿ÒÖ™Aú?5Q³;‹Œğ™v†”¬{?{g»`ggGã…;S¸z-äe2×Co4uOìNNÏƒŞàÃ\Zñ|:3ršñ7ëÄO½Aw|49<¼o«Šbå!ñÈ Ixï=ŠÚğ¾×ï.2ù2úcCú€„–ëL‚H×12ÌÒ¢¬†½£"èT3­ÈgEPb¢‰!³Œµu/³hÃ´++‡æ¤ñ ç»¡«c˜™z¸úÚƒtÓmiíˆ;Í‡‘!¯{Añ¨šTO@/÷/Ö<„älĞï÷Æİô<Z™,zÄ4ÊÂL-í:ÈÃüĞí;ıŞ]œuûŸñ/úŠ§a’–QŠähWÎPeæJ‰»·âXÖ6¤Ç™uH)4œ…†R’šŠ®/XL”›È…ØÒÖ,Š@(}€CáE­{n20ut\ôP‘Gû@D?+İu&ÜDñòR†Vûğ¿•‚V^!i‘á¥ãDÍ¸Æ8.…X j÷,HÇWñ?…ZÁÉt­Or´üå,- ¬b-ùˆ/emæŠªˆª¯ÜŒĞˆ•aLµM¡2úÌv1ÆJ9PÏ++üd0bÏ$‹›çór‹w¦e¡Ñ
 Ã€YS2á.ÏX5Ù‹¹¡†´SbH€bnM˜8œ3ô]K„ä4­­…ú~e¾fSéûšN¡;v!ş?R8Ì 3ü‹’K	lC!ñ<tmŠ„q"Ì¬¯(È×­È@¾ºÏÒt
%5Œ24’tZü»6…?,ƒ;å]*@~v#NÌ`Î}¼\F	Fhê‘¥ùYIçAB†ËgÊÏs˜Òà[% <O#pï©ïÚzjúAÈqøaj¦#ö„œå'C¦¡)ğ‡•Áád‘É‚9rÙGwBèz|l?Y´µ¶JK@$¼G4q€gœò˜‰ ¸A\aøtBT]$îÙWÄÈ„qİÒ"*ïDÈ
-.*L&º—ô5+pù$„~Ãîï\ß€ãÎp2>™ôO;}¸›™|_\¶	ŠÄ—7åKyçJ/e5 a#&Ü!³…(õ¦|wšÃKd.áù
¥ˆµ3EÃsê(÷·¨`×xbñN86êÒr‹BˆñˆPƒÒã-(!_›ÇtovÔí¿op&æÉ¬5È‰‘˜¦!EÛã«îL:h¾eŒï0r%]pmÁídN’v3ª	ñIÓ¤	/8ºŒ³ó&Bé».9‚xçZ Ê‘ÂZ¸6Ê±m"aq¼ˆ3šá½TYnMäîc;R>Ç¦SÊäM”Mƒ¬
ª<nkæF!²”Ç´á¦¸¡ĞPE].ŠÒMqCv†Ø›¤‡~Îfî»Vd~ãÛO,éÑDÔnÛjZ„/ÇÊJ&ÖO®hâòÂús>	]]€^\_R¢Îc?U>øìÚÁg>·jğ%ƒ'ëìÓ!Ÿ‹]Tš”[]TZ”„]T¶¡®Ãàï
JóİÊtÉ5Wì¡Ï’„8Î–2™Â|Q–&<~CĞÊàeœór<áã‹X± ®˜gy¶kÀ«OË!”'kTË“Å²Ì1ãJöÉ–E"'ÍËC<,Ì®(N»Bğ™§ÖÏ“[—eUAÜ$ñógTJ‚	ª*ãíútµ$á9š·‘+
*­ı"İëê²Ç+<Ku`4>şÎ*Ù_T1sÅEß„¸Ñ^Á
å\°”"Û‰3U¸!ÏX©Ò5a<TÛßÎÁÖà·ßöVÌ åôÏ0&&ö»ÁWÌD~ÿ&¬|•*Ç¤€xLR„2Œòwr ê7ÓÈÂ …Ó$ÅzÆrò‡³|…Êñ]çğ‡qoÜï¶U
LĞà„3ß®g^$¢‘ ê0öC¯©yùg„Z¼N/S Ö=Ã°sÚ9A9eÚud¢‘²ğè'"pöıØéŸuGíJµò ¡o©»7uK»bò+ºÂh[E–èìJÓoB3´èô!Yô<—c£Ì¹˜§O€0§µA½pF|DnO–s·ë¸=hîÂîÆ"YbÿÊ³ş&4Kj%ãU(aß´Rp.n¾•çÂ‰ğ­üöÁKD?xÙB_ør»¦¸^Ø®ü[Şá´,q=‹rT¹ŒWÄ™Î1ÖînàŸüÒ*Íù?kEDù¶ã	Ìa¢³áñqÑÆÜFäˆ¸²¤j¹À›¹—ÊøĞ6~’Ã™a¥	Şçìá†oJšÌmâ”LĞ%šO‡Dh¡pû9¡Œ	cFYÿ¯´—sº{æıd6%Ç'dúBìvìÈU‚Îp/,'Èî#‚ªœ©†YxåLTõô~¥Cø÷›İÇ¢ıÒÕË££­*•j¼Ülô$‰
s‡5T–ÔP„néµM>Øº@ÅÅ-xü¨eèfãÖİ8ŞËÓÍ…¹éªÒ›wzƒ¢Ù"îfa¬…ÚóußOzãîq[­×¥M©›”9Wšêbc§SõÜŠ^÷Óç˜»ÄÒ“"3'’8HX.`Á1¢^(íÖ¼¦Ÿ|¥$ŸÃœŸ/áüèäãàòõy×	™I½4´ø Aèô_îm%À¹¬à¼ Ù—â=Bù .‘›Yş-!ÚÚmñ1×Æ¼©r1dº‚z”y#¤â{Z4Ş†ÆlÚ^—¾ìQG™7=Y¸%Öw™ùåïpR{Éãˆ×Šn?‰àË«ÉŒThİ>Í)†1ÖåÄDöÊƒ€¦—oÔ’^úæ.ĞRS,ã“<g¥˜[b¥HL\*üù¡¥ù¯U‹__ÉÍ9ß;jkåáÛ½ÖœÑÊ³¿ÿ=Ön%~Ïûş÷ÍÎÎÒ÷ß­·Şÿ6wZë÷¿EK_ªìeº4tÏSJßJt™–QUi¸òpøÓOs¨¼#']ùê½ÂyOõşã'²P·àäê4FÁ¡çf¾è?Æ†)øŒ%c=	f+/ÖíÏÑÿ<_ÿıßnníô{{çÍZÿÿ’÷ÿ±Š¾Ã°ÚÊØ˜(i¦›ï
M›å{l-œĞîƒÍ"\¦”1ş¤»ÆQ÷Ãqw€1YçxØï0ÄÂ–ŒÎ'bÄw(&¿ÊÃx—~`L£¿æ7¡°¿oÏ/kÊƒR¢!Ëu½C~i„¡Ñ¾R·[@¢{0~ß?Æü¹_z(Gb Fx‹A“.Ie{Ñ½{2ñÂ4ôï1/•ĞâÑÿ`oLl„ôov¹‘ªJÊ§¾†zó5¨ƒîGµ¶_Ä¸x¦ıÛ"T?Ğƒz«ê÷gº“-ÄWG½ƒN_ å…tëjĞVJ‡ëz5;Nıñø‹«¥ttT…#+`Õæï"'°rÂ 5·!ÿ›Z.fšÈº~DyßyAz.ùBÜˆ^ŠÄl”L‹»yšú_sÉçx÷j©IıS×ç‚fr*øç]N$±çÕ+zXMÌF92öötºE|÷ÔxÒ”ÀŒÄ=ÆñØkÒ?'·ö–\N‘½tî_ÄÜ¿àÜ…íb§˜^Ì_tşË%½¤B‰Ém’æ4øi–Jqç«Wü{NÿÈ“(® aÜ½ÔØà+å?|}O¼x³SM¶R[„“¬B–kXˆÊù²
9aÜbtÓ^„|J÷ÃÕdW\ Äd¾¹ïk÷\ƒ¥«Ùnq¨ª`Æë"ÏEûú=.–â±xbİ¯!P M£ïª„xÔŸC@Ï©V£ÏªÉR1’ê~ÒOµá%û¤£‘åd»w3j¡±E’>#ß!İš¯C±u[·u[·u[·u[·u[·u[·u[·u[·u[·u[·¯°ızXÏ( P  