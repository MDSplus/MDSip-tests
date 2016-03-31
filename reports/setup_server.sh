#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3731806791"
MD5="1e320645e1c55ba71128e97630b4821d"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4024"
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
	echo Date of packaging: Thu Mar 31 10:24:20 CEST 2016
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
‹ ´ŞüVíkSGÒ_µ¿¢³Ò9¶`_ÅEÙQEqr@©–İÚ°¯Û˜ı÷ë™}"	Ûg'¾*M]Œv¦»çÑï¹Ææ³¯Ş¶°½Şİ¥¿Í×»[Ù¿q{Öl½zıº¹ûºõjçÙVskw«õvŸı-
BÍx¦9†Ï´åpOÿŸ¶ÆfÀÂÈk³¿‹ÿ­İ×Íÿ[­&òkÍÿ¯ŞÊßm^™Îf0S”2°f®Ì÷]?PP2 ÎetxÚãn»R½Òæh6µ²¥ÖäØä¨wŠc†ég†öÁsıÆÓwİñä§“Ñ¸]yÈ|íµ-W×¬™„óğğä4L_{í¢°áFÃ““~
È?÷Ú›¡ímÚF`z“qåøh4ìŸÄ:2_ş&_¡xVÌ	¼7ÌÎù9q¢JÿhÒïıxÚ9ım2ìŒ*ZæÕ^å¡ ”¬Ab…†©(G½Nÿä]Û05Ë½VÅóM'œÌ˜åUkğ èZoŞ@÷ä­rh×l*)s ^‡s×M×	.á\wm…öRQ@49ÖEK>gÖë4Qâvügf Ô-ºh¡i;)4IKÀü[æßgèÂƒ(`T6Õ"+ä,¬%4¤x®kÕr4¨P”ˆBº>Ãn'Cµ”RÅ)Ñ[$Šk¸r&É3÷İ7=$îF¾ÎäWŒÿ•'V<¡zŒF¹&ºäîxĞ1øÓa¡ñ$8”é\ÇĞb,Ñõ 8#v-P·˜æä¡™í…÷ÈK– Ä‡Ìt<á{…$
Õ¤\OóºmĞ/TæùÁr73-çç¨ÚMÚm¨oÀå%ìƒáÆÓ‚–AŒ›ÉZ’–Š×£¡¸¥²¾„ÔÒÁııÇ³f¥a)"·s.H¸¥`d…í9NŞ÷G'ï'£Ş¿»íííİİíÖÓ˜GİÏŞåpC?bà—¯tfN?í =UJ¥RÎ¸¶VÏ­Oš§^ûÌE_¡W½ù”©6jÿ;-hºb¸:7s
çP)Cİ
¡	$Ò¨&©ü2}æ‚Úst×']É(EÎPŞ…PÃÔõQÑ"£ìÈS›Ú†ªd%šÊm<¶iäp½‰§…3nİÌ¾!ÃW÷ ïÒæ«Æ6ÉU¬÷#¾)ƒd.'\ÿùÌí3IÈ€]Ûhy'ù{ÖcÌ@²Èãã`CŸ9Oƒ"”f?5‹®—/Pá
xç›!ã€0%Sfk7dnÑ“—3Ğ#d0¹™Ä&Ò‘j7L N8êóçğØ÷=46S²ªÔÊ°ùåš –w#¢}>µ/¶¶ŒpÓú¤d³[ÍJ¤¿õÓo&bíP¹A‘Ê9|‡òê^Ü9GÄc¿À10õ†óœŒ“1Ã="*ê"DhPˆ@}H)ö6P‰à¹+|å;u.‰Ãz¦Ak |ò	‰o¥m3ƒt?ÙPd„_gCHxÁB±÷£7D°6tv4~´¡e|K&yè&£îé/İÓÉéÙ`Ğ¼›«B¾ücĞÀŒœüÍòÿkoĞMOoÛª"Ö@yH|rfŞ{ü~ŞöúİEæ]Fº"8lH{ŸĞrIé:FYZ”aÁ°wTj¦ù¬Jl¢C41<–qµîem˜veåĞœ4öó|7tu)ÓQBOB W¿AİO7İ––=¸ÓÌ°pòºªIµô¨qù]ÍÁCHAÎıŞqoÜMÀC¡•)Àr G¬@£,ÌÔÒ®ƒ<ÌÏİî°ÓïıÒ…ÁÉQ·ßùÿ¢_xÚ&)¥C~våáUf®”¸++eBzœY“_€”BÃYh(%©©èæ‚ÅD¹I\ˆ-Ì¢hƒR8Óºç¶ÓDÇEoy´ÔHô©2™Ñ]ÇaÂ%”//eh~°ïÿ[)hå’^:¾@ÔŒkŒÙRˆ¢vÏ‚t|ÿS¨œL×ú$GËŸÎÒÊ*Ö’søTÖ–a®¨Š¨€ğ*ÍXÆT‘*£Ïlã©”³eë¼ŠÂO£ãñL²±yî.·xgZºÍ¡`9˜5%îòìTó½˜jH;%†(¾Ö„‰Ã9CßµDø½AÓÚZ¨Ïàæ»€`6U¾¯é¦câÿ#…Ã¨0ËÇ¿(¹ô‘À6ÏC×¦¨'Â,úŠzİŠè«{ğ,M§°QÃˆ2A#I§Å_±kSøÃ2¸SŞe¡4à77âÄæÜÇ»Àåh”L„¦YšŸÕ‘t$¤aø°|¦ü<‡)¾UÀóÔ1Ú&ñú®Í¡§¦„‡¦f:bOÈY~2Ôi:šÒXNI‘,¸‘c —}t'„®ÇÇ¦áñ“%@[k›¡´DÉ{IxÖÉ¹ ™‚Ä†O'D•Dâ8‘}EŒLÈÑ} -¢òA„¬àÑâ¢Âd¢{I_³—OBè7ìşÎõ8î'ã“Iÿä°Ó‡»™É÷Åe› Hìx)S°”w®ôRV0babÁ}2[ˆRoÊ×p§9¼†á¯PŠX8S4<0§r‹
v'ï„c£¾ -¹(„5(=Ş‚òµyL7q1ñfGİşÛ×abÌPƒlA‰iR´=¾ÚàÎ¤ƒæ[Æğğ³bÒ×ÜNæ$i×1{jÀ‘ Ÿ4Mšğ‚£Ëx1;o"”¾ë’#ˆw®¢ô(¬…k£Û&Ç‹Ø8£ŞK•åÖDî>¶S!ånl:¥¬İDÙ4Èª Êã¶fn"KyüHënŠ
UÔå¢(İ7d÷`ˆ½Iz˜Íaá`æŞ±[aE6àO¾ıÄ’MD¶­¦÷r\¬d‚üä:&./¬5çÎÕÅæÅuï%åè<öS¥‚®|t‘àc+Qx²6À>0òIØE¥IIÕE¥EÙ×Eeê:lÁÁşŞá©Ÿ4ß­L—¼-Qs…ú,I~ãl)“)Ì¥gÂã7­^Æ9/Ç>¾ˆâŠùx–g»¼ø°By²µ<Y,Ëä2®ZóÜã,9©Ä­J“EgËËC<,Ì®(N»Bğ™çÔ_2©ÆdÂÇU–UqÄÏÙÊF’
f$¨ªŒ·ëÓÕ’„çhÜF®(p¨q‘â#Êñ>·8ğUª£ñÉğ3+bQuÌ—zâF{+”sÁR(ËGU¸!ÏX©Ò•`<TÛßÎÁÖVP—2ú?QŸ%æö»Á7Ì<~Ç&¬{•)Æ¤xP‹ÕH(Á(ï¢n3,L8MR¨¯X2~wÖƒoP)~ìş<îûİ¶J	špæ»ÑõÌ‹D@FÂî`È55¯#_ãŒP‹Wæe
¼º‡cvN;Ç#(§L»L4Nı„BÎ¾_:ı³î¨]©V!ô)u÷¦niWÌB~EWe«ÈÁ]r]iúMh†İs>$‹'ãrl”¹âô	æ²6¨ÎˆÈíÉ2aîı·Í]ØİÂ„#«CìßSy¶ß„fI­d¼¡
%ìÛ‚V
ÎÅMÀ·²à\8¾•ß>xèÏ[èŸo××Û•Éû1ü€6‚%.gÑs*—ñÊƒ8Ó9ÆÀÚİ|ÿÀ/v¡Òœ_+"Ê÷O`¶£ˆ‹6æ¬0"Ä•%UËˆØÌ½SÆw¶ñ“lÎ+Mï>g7zSÒdn§ğçŸ{PãÅıºC¢@´P
¸íœP&Œ„1“¬ÿGÚÊ9İ/óşâJãô1ÇÓ•î[%Øl7÷¼’xvjT•³ÔĞOœ‰¤Ş«tßÚ^³{X´WÜ¨ò(¤h«J¥/5-I¢ÂÇa•!5[zI“®.Paqù?jºÙ85G7ïòtsaícºªô¢ÇŞ h®HĞ…›Y[á™6ÅüGİ·“Ş¸{ÜVëuiKê&eÊ•¦ºØÈéT-·bC×ığ1f.±pÇ¤€ÇÌ‰$–˜ÇD0%Œh‡Ê@»5¯©¤'_ É§.çgÃK8?:y?¸|yŞuBæ_R/Í"->h:ı—{7F	o.8/Hõ%¤xƒN>ˆKäæ•ÿBˆ6v[|ŒÅ•0oª\™¬ †eŞÿ¨£ø¶¡1›¶—À¥¯vÔQæ½Nn‰Õ]fvù›ÔNò‡6bÁµ¢{ãÏøòj2:·E3Šá‹€uùã/‘­ò `ÉåÀµ¤—¾ùƒ
´ĞÃø$ÏY)æX)—_>Ä¡´>âµiñšë¹ç{Gm­<ü°×Â­3ïµFÉà×}ÿûjggéûïÖã÷¿Íõûß¿¤¥/Uö2]ºç)¥¤—ºŠLË(Œª4\y8üõ×9TŞp7şÔ{…òîêıÇOd¡nÁÉÕïh°‚CÏÍ|Ñ%~ŒSşğKÆzÌV­Û—Ñÿ<_ÿıßnníô{{çÕZÿÿ’÷ÿ±Š¾ÁĞÛÊØ˜(i¦›ï
M›å{l-œĞîƒÍ"\¦”1F¥ûÇQ÷İqw€q[çxØï0Ã–ŒÎ'bÄ|(&¿ŞÃ˜˜~`Ü£¿ä·£°¿oÏ/kÊƒR¢!Ëu½C~‘„áÓ¾R7^@¢»1ş`Œù!rÑôPÄ@ğ+]’Êö:¢{7ödâ…ièßcÄ^*¡Å£ÿ;ÁŞ™0Øéß68ìr#U•”O}	õæKPİ÷jm¿ˆ=pñL7ú·D¨~ õVÕŸÎŞu'[ˆ¯zï¾@70é&Ö ­”×õjvœúãñ'WKéè¨
!FVÀªÍÏ"'°rÂ 6·!ÿ›Z.f¢Èº’DyßyAz.ùBÜˆ^Äl”L‹»yÑšú_sÉçx÷j©IıS×ç‚fr*øçMN$±çÅzXMÌF92öötºY|óÔ÷xÒ”äŒÄİÆúØkÒ?'·ö–\N‘½tîßÅÜ¿ãÜ…íb§˜^Ì_tşû%½®B‰Ém’æ4øi–Jqç‹ü{NÿÈ“(® aÜ½ŞØà+å?|}K¼xµSM¶R[„“¬B–kXˆÊù²
9aÜbtÓ^„|JwÆÕdW\ Äd¾¹ïk÷\ƒ¥«Ùnq¨ª`ÆË"ÏEûú=.–â±xbİ/!P M£ïª„xÔŸC@Ï©–£ÏªÉR1’ê~ĞOÇá9û £‘åd»w3ê¤±E’>#ß!İš¯C±u[·u[·u[·u[·u[·u[·u[·u[·u[·u[·o°ı‹íÈ P  