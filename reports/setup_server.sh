#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3194066456"
MD5="dd7ec3b95f2db2aa0fd019de39bad502"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3968"
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
	echo Date of packaging: Mon Mar 21 15:15:16 CET 2016
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
‹ ôğVíkSG’¯Ú_ÑYt„-ØW`qQ@&ª¡B"N(Õ²;BkV»{ûà¬ÿ~İ3³O$Ûqª4u1Ú™î™~÷Ì\u}å«·lo¶·éoíÍöFúoÔVjõ×o¶îõÖÊFmcëõ›Ø^ù-ôÍXÑlÃcÚ|¸§Æÿ¡­ºî³ t«şøï’}«VÏË¿^{½½Kùõ¶úÃú¥i¯ûcEYvgàØÀ<Ïñ|5*LQúû'íŞ Û<j5Š¥KÍg¶6a 7Ô²´OpÌ0½ÔÂî\Ç`Ğ<9l†¿÷âCêk§a9ºf?˜æ€{Ç')`úÚiüÕ#×ïw@ş¹ÓX&îúÄğMw0"®ô{Ó¾XçCêCß[ç!×
ı)·{YÀ)ç'ªt†öÏ'Í“?†½æà—< e^îr@œèLğÀ0å İì6S³œ+EQ\Ï´ƒá˜Yn©Š®ğö-´ß)§¾vÅv ˜H*8sÜÀtlÿÎtg2Am½PMEŸÑâÏñÇJ…&*CÔ®PğÁØôºEWí"4I &5ñ™wÃ<à¢	¸dúÌ€’ÁFZh\vå˜†4|×q¬r†õ êQğÇcØm`h–PÊÉ6!zƒDq—Ï$YìÜ‚¯{¦‹ÄĞÓ™üŠp¢¿’cyUr`ä)È4Ñ%wï3ßGFGàw¦ÍãIpä”i_EĞb,™Ñq!?#vÍP·˜fg¡ÙÄîQ–,F‰˜Ìtäğ½B…ö±º
®æùô‰A¿ĞŠæù;ÊíØ´œ¡M×Th4 ²°†M:º1nÆk‰[¢^†¢–èú\òLswwÏšÖ†¹ˆÜÁ9 áæ‚‘cNg¿7|ßî¿öÛÿm567···¶6ëOc´~>=Ìà^ÈÁÏ_éØ}b;U
…BÆ«ÖÏõOš§RşÌE_b8½ş”©ÖÊó5]1£š9‚3(®BÅ
 ¤Òh&‰ş2}ì€Ú¶uÇ#[IENQß…RÃÈñĞ€Ñ#£îû(S»Úªª¤5jÊ}<¶QhsR½¡«cîİlrM¯âB6–M­S¨X4î…|?RÉ]¹ıó™3f’>»š çúæŸìIX—1É¢ŒçÁ³ŸE(mòÔ8¼š¿@…à­gŒÂˆ\ÙD»&w‹˜¢œiƒ¢€)ÌÄ>‘Xª]3:ä¨/^Àã ŸğP]OPÈ«R[…õ/×µlíó©}±µ¥”›Ö'5›İhV¬íøÍ“ŸvošÑWrLØ3Áh¹ìˆº÷UÊ}¨ô Ğ]Ø{¤ìØ[Eƒ€Jd¼ÅÔphÖ5« å3ã$mê—Yqh3V‚½Ï^1ÁÎXñéÁàÑŠ§_Uë0T3#£{³ÖıŞî¶Ãıãî»†ªÈ4ÑWbŒ,÷î£hÛ€wíNk–S•ù¥HÉªÒËÆ´{è‡º¹Wš4ĞkäAGši…Ëƒ’”ˆ‰&&¥2›ÕİÔ¢Ó×.­šd\®ç‰\2Jèqàuôk´¸dÓéOcˆ[ÍrÌH‘×]?Ïª•êÇ¢ŠvšLH@N»öQ{ĞJXà2o(ïù@D#€úi˜‘¥]ùY˜_[­^³Óş­İãƒV§ùşEoüş¤Ù‹*B¼íâÃi¿u2U
<€äÇÒÖ°3íhsRi¸¥ @‡\üÙD¹óš‰-½Å¬O	:ì‹8eİs£ÇâÌv0„.í-#™,!tÇ¶™pÄ«ˆ—Õ2ô#Ø÷€ÿ-T´Õšn2>CÕŒ+Ì”ˆªvÏüd|‘ü¨’LÖú¤DW?]¤9”E¢%/ÿ©¢]…©¢*âÀŠôÑ‰­Â€ªo™¯ 1zlâ`“HÖ§™ZpÎ`N:K#6¯˜åoMË}¬Ù”¢>³FäÂ^j.Š«/i'Ä eµšpq8gà9–Hz×hÚ‰ècø“y Ø„êt¤ïi:%ÇØ…øÿJà0×¬­ñ/j.}Ä°U…ÔskoTkœk×KJ£u+4P¡/ïÁµ4’5ó¸4É®LÛÆa$âŒx—…P…?œ3˜}í—£Q
˜zhi^ÚF’y?,˜);Ï~Bƒo• Ÿ:æ¸¤Ş#Ï™pè‘éùÇáÌÔL[ì	%Ë9C¦¢+ñ‡•Âád‘é‚ÚJÙÃpBèzÄ6ÙO }íÄ¤' HŞ%HšØG^Ç|A37ˆ+08Dw$=°ÃÉ%	2&CRÄğ´ˆÊ;º‚¬ÅEñD÷’¾fùŸ„Ğ¯Ùı­ãpÔìÇÃÎñ~³·c“ï‹ë6A‘Úñ“CÉ`©ïÜè¥®ú4,`ÄÂÄ"ü{?`¡Jí_Ã­fóC(L›¿Â("kàBÑavõşì
9í„c£½ -¥(”Y„”°7g„|m.ÓM\L´Ù~«ó®Êm˜„'ëB?}ƒˆ$4)N\¾ZÿÖ$Fó-cw‹µ(Ù‚3Òç$m×±f©Â qš&eÁÑ‘\ÕRóÆJé9‚hçš/ü„·p&¨Ç	ö"6Îh÷Òd¹7‘»üT@¨V6Q7ò*hò¸­±(R?ÒzD˜âBCu¸*Ê0ÅÙ=bo’ÖĞ~ãŒ[v#¼È|äÛ=éÁPœ6Ôä|{5:,¦²õøö#:Wy´›-ófíJì¹ÇÌiˆ4áöSú³«óg—æÏ­ËŸQ”?Y‘³;¦C¶š:/Ö¨::/Ö©Œ:/nBE‡ØÛÃß[¼H“î»ê’—jæ8E¤>sJNY[=¤*…é¬:KDüª •ÂKçùx"Æç±"E\0¢èã‰cÀË»ùÊ“§@
vˆr0:^T¸Šš4ª_çç,ç<ŞÛ›Y&QQšHh„¯r¿d™+·,jvq’çÀ
>’2©2'®ŒKYdÜ-8.PiYçÉ6æ|Å³Ÿşà¸÷™ç=ßèìÇWVCâhc;•3!8…ân	®)Ktá•wÁ›d`Ë¨KúKÔ¿ÖÊ~§Õì~ÇÂã7HÂ‹–H‚5Ş#ãrd
ÂúÙ[%ç#£ĞÂ€ÓüÊFqxÚ†ïĞ(~nîÿ:h:­†JE0öœğjì†"ÚûP¾ğ˜ÚŒÌ«ĞÓ¸ Ôü…ğ*%8­ıôš'Í£>Vö±Ğ®Bsˆu²~H!˜‹ï·fç´ÕoKÅA]~Å¹®XÚ%³P^á%f³*J°@W8—š~˜E·xñ¢§ñ¸ë§.yÅ„8}„5ãÔs»ÏGäöäq\æ~ø·µmØŞÀXÏ‘Õöï¨¼ª®A­ SÁJ…öm@=çê&àëip®œ_OÁoî½@ô½uQ/6ËŠãâäí~`¿ÑåÏ¬W%®ãÅÁÓ)æšÚí5üøÀ¯-¡X›şXÎ#Êg	O`Ö	sd*<_!)N°6„>n,‰Y™~=”2«'1óˆŞ4êkà'ù0œºŞ].îôFdÉÜàãÇ K6t6©ÑB-à¾sH'ÆŠ­ò?é+§t{ÊûËˆ+A8>ÓÇ¹+C°J°én=%ñôÔ¨$g)c°á}ûó÷*Á÷¶×ôfí7ª´ûÃ~ëä·ÖÉğä´ÛmwªR,EKMq+Z±pÃQ*BÇ}ªÎ½É€£ñ©´|åİÔÊ²t£ô+K7>ƒntqÔlwóîŠ]„™Yª¡»Xó´ŞÛƒÖQC­T¤/©˜T‘kêl'§Ó©´9ºÖİsÜ\ìáÈ ˜J$,0ˆ`éÒÏ•®vc^ÑÑ™|_#rœö.àìàø}÷âÕYË˜wA•²t‹´x¿Jèô_æ9–™$ı,§Õà=Ò)Ä%r÷Ê¡D»)>âÂ“7U.†\–A÷S¯[Ô~tÃˆNÛĞØ„¶Ã%oRÔ~ê5Jn×çvù’ÄOòg$bÁå|xã—ù|yeYé	›Û…¼ÅôEÀ:üi“¨
yR0ÃåràµrÜKßü¹ zhÊa<Òç´s¬ä‰‰Ãú/ŸâPùò3`ñVé;¹óå{Gk->ü´SÇ­¯,Û?ìıï‘vÍ¨òıºï_omÍ}ÿ]S{ôş·şfùş÷[´äÁÊNê½KUw]¥ğ“ç—¡i¹Q•†‹û¿ÿ>…â[ïü•vî)„¼ÌJçñY¨XG†|ù=»¿ïºı±'ºÄaÊcñX[‚M–æKÙV®ƒıoÖ6¶rö¿‰miÿßäıd¢o±Fq„1VÇ{JÒï†éd»sÂ²=-çĞîıõ<\¦¬b2O¢ıÖáQ«‹	nó¨×iõ1_ÅvO†¢Ï_ (&¿oÄâ~`‚¨¿â×µ°†¿oÎ.ÊÊƒR !ËqÜ}~³…yæ®RWp@¢Ë:ş(a€Ù!Êeè9 ‰€ªÁf º$•îµE÷vÉÄCÓÀ»ÇÒ¦P@Gÿw‚ra°Ğ¿°Ù-dFJ*Ÿú
*µW v[ïÕòn»ë O×lú·D¨²§õ–Ô_N[ÃÄWûíÃn³#ĞL™º6h+Ãm½”§şhü‰Å•::šBÀz¡å³Rí³È	¬Ì†0ÛÏlˆCàÿF–ƒ%û
‡îÈQŞw–Ó¾'¤ç,‘¥Ğ¢n~BOı¯€Ù†”s4ˆ{4‰T£ş‘ãqE39üó6£’Øóò%½¯&a£;;:]u¾}ê{ä4Uƒ}qY‡Eöšô‡ÃÉ­]%„S¤T/™ûƒ˜ûÎÛ.vŠéÅüÁ ³ôÜM$"·N–SåÜ,¢Î—/ù÷”ş‘œÈ¯ Ü='Yã+å?sr}G²x½UŠ·R…“,B–k˜‰Êå²9Ülts2ù„.±Kñ®¸Bˆñ|9rMÏÓî¹"úsW³YçP%!ŒWy™	Š¤ö•=zc,Õcö2Äº_A4¡@–Fß%	ñ¨?ƒ€"Ò¡—>.ÅKÅLªu§3~n/ØjDJ”Ñaì®Ş5:PÎ©-’ôXz6ÙÖt™Š-Û²-Û²-Û²-Û²-Û²-Û²-Û²-Û²-Û²-Û²}‡íÿx× P  