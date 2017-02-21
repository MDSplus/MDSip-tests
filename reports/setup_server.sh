#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1137490443"
MD5="3708a5e2a3d26a162ec06a6968056e78"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4123"
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
	echo Date of packaging: Tue Feb 21 11:33:06 CET 2017
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
‹ b¬XíksÛ62_Å_±¥t©äD²%ÛÍùªÚJª©,k,¹iÏöhh²S$?êè¿ß. >õp’ÖmoN˜»Xvì@k›/½ma{³»Këov·Ò£ö¢¾½µ»½UßŞİi¼Øªoí 8ì¾øZèšğB³iËáÿmµMŸ¡[ó'•ü»[õFNşúîÎØZËÿÙ[ñ›Í+ÓŞô'ŠRvoàØÀ<Ïñ|5ªLQ‡§ş°×:n7Kå+Íg¶6e –¶ÔŠuNqÌ0½ÔÂî]Ç`Ø:}ß~<›¥ÇÔ×^ÓrtÍš8~0Ë÷ONSÀôµ×ü'*KnĞ?9é&€üs¯¹LİÍ©á›î(`D\9>ô»gÁçcêCßÛäŒŠk…şŒÀ;ı,àŒï'ñĞ=u;?œ¶Nõ[Ãóğ–yµWzÌÅ@Ğ…Xa*ÊQ§Õ=yß4LÍr®Eq=ÓFf¹å
<*ºÀÛ·Ğ>y§œùÚ5ÛƒR"#¨VáÜqÓ±ıK8×éu÷RQ@49}VE‹?'ŸªUš¨Q»F5&¦Ô-ºbh¡i9	4)Ï¼[æ_gàÀƒĞg”6ÖB+à’¬Ä4|¤á»cU24¨P£ˆ‚8Ãn; C´„RNÒ	Ñ[$Š<\9>“dı‰s¾î™.wBOgò+Â‰şÊËïP5F~#€L]rõ>ó}ÜèüŞ´Y`<	;eÚ×´Kft\ÈÏˆ]‹'Ô-¦ÙYh6uƒ”%‹Q¢Mf:îğC„zš ‹–&’Æ…´-«XWó|úÔ _hÿóü=ånbZÎÏÑÔUh6¡º——°†Í::1nÆ|Ç-QÅ¹¡¨%v±„|ÚÒÁııùYÓš³‘»F$ÜR0r©Â]öG:½£“£AçßíæööîîÎÎvãiÌ£ögï3¸²9øåœNÌñ—m@lÓJ¡PÈøãÆêY ñEóT+_Éôâ›/™j£òûi1_ÓÃ±1šc8‡RªV u •F“Jô—éÔ­;ÙUÊ(jp†ú.”Æ‡ÆŞußG™êÜ-×T%­¹PWÆhkØÆ¡Í!HõF®Lx$@°é9ÉªÙ(8[5¶IaeÕ¸òõH$×:â¾‚ÏÜ\0“„ôÙõ½ôÈ7cOÂºŒH%`|là1ûiP„Ò¦OAMÂëå*Ü ï<3`ÆäÊ¦Ú¹ft„MôL!)í?Š	ÔG}ùrAO
 ¶™ W¥V„Í?®	jÙ#Ú×SûÃxK)7ñ'5›İjV¬íø­O˜~3¼PAm”e5Ü¿Á0òèn40Sá2¶Kbuú³Œ¦“KÃ)ÆÈå`,ĞERQ£ÜÔ‡j4Ì™	öÖ( ¾T"³/}£.€C¦8¬k¤”Ï@‘!Æ´xfc Î®-4‚çZ’^À3ö~öÚvÁÚÎ†×¦p[(Ïx®ÇÎ`4hŸşÜ>õzŞû™*,ãùì“	fd¬ã/¶‹_:½öğhtxÒ{×T™ôúÊ£R@ÉŒ‚w.hÂ»N·¾Ì“EjI¢T{ä‡ºÉcš
ÕgĞïÅ0cÍ´BåaH$´a&¦Ó2×]bĞ0}íÊÊÀÛRp='ptL:“nB(ø~ƒ¦,©)¹R¸ÓÌ ·F¢¤»~~éu:OÀY ˆªÙ¸¦dì¬×íw†m\‘‹ú&+€£s»*F|pli×~vğ§v»ßêv~nCïä¨İmıŠÑ¹8mõ¥€…—£†²9CÍ!#Ì¦m7&í«ó0R¸|ãv„Ê_Bû±ÅøÒ,ÒçÃ¡wÖ·k¬mCIèÒ*Ğl0 ÊªEwl›	^D¼¬z «À¾Gü¿l‹¥˜¤øs
n2¾@qŒkL¸ˆúóÀüd|•À¨U‚L˜}Z 	ãŸ/ØÎJ“3ÿra¦¨Š8÷àg3ô7ERÙ/“47ML‰ùúTœó³¾?˜à'RĞˆÍKu¹Ì;Ó²Ğãk6å»Ï¬1y[‡£š‹BÆRNCÚ	1$@)²&\Îx%2èšvªú~c6¥¤ïi:eÚØ…øÿHà0q,êñ/ê/}Ä°5…”ô‹~Tnœ‹æ+ÊÉu+4P­¯Àµ42?“Âô˜¿b×¦]EpÆ¼ËB3¨Á¯NÈ‰Ì~ˆVìhT¦Zš—¶”d$¤aÌ_>SvÃ„_*à~ê˜0“’=gÊ¡Ç¦ç‡o¦fÚbM(Y¾3ÔiÚ!úÌX)NI‘.8¡m ”=Œ„®GÛ¦áö“?@ß:5éˆ’w	’&öq¯ã}A3ˆ†G;Dç‡$=°Ãé	2&CRÄ€´ˆÊ;º‚[‹LñD’¾fùŸ„ĞoØÃãpÜê†'£îÉa«w“¯‹ë6A‘ÚñL¹ÁRß¹éK]õiXÀÆşƒ°©P¥Î˜óp§Ùüô3Ü_a‘5p¡h¸avõşìw,Z	ÇF{AZ6JQ(1nZP²½9#ä¼¹L7‘™h±ƒv÷]Û0	O™~úüIhRœºœ[ÿÎ¤æKÆ„î“L²g*¤ÏIÚ®cTƒ#A#Úiš4–G—©]zŞX)=Ç¡p­\óÅI£ğÎõxj"a±½ˆ3šÁƒ4YîMäê#?PùÅÆc*¼MÔMƒ¼
š<.kâ„Š”§zÄVÜQhh¢WE¬¸#{ C¬MÒÃ‚Ürû çİ
/²ŸøòcOz4Ç²M59f/F‡¥TZ_Â¬<ZÎÖŒ«Ï–Ÿv/9}Îbç«ı|ÀP–ÖúK!ç*ıÕ©:)`ªÊ_“ÔøsXWÑ2áââ¢Ô (ªúşäBª*vÏôTe…š?ÆÁ‡ßÙäX5yKÂ,: Ìa¸²N¨b
,ÄèÇ6TuØ‚%–L€õ’š=yÖ’2™«¼ŠºÀ2*UBÌ.Ts†ùN¤5AvD*+XMBdKDÆÀI,ã—…SÇ€W÷Ë!”'¶–W—EY”FGå¿¯ÀµsTg¯È¹ø¡ŞÁÁ"vyñœhÀ2¡¼r¼("Ä5DœÍÖZêµ*óÿêxµ†áNš÷Ö+ÎITâş"YíêÓ’ßw¢ğ,G
ƒáIÿ+×ş¤£6GÜ&HÍ¢PÎ…H9à.I2e¸¡]*Ó]d4TÙoš­À§O{+fšú»g˜=“»íVïo,D~É'A™*¶Ç›3@Ü&iNÂÙ‹?'@ãĞÂT‰Ó$ÃzÆsè÷gøÇ­ÃŸ†a·İT)EB‡L<'¼¸¡È‹|¨Â@øLÇæuèi\jşÎ¾H©`ûpıÖiëx ÅDh×¡‰NÊÂ­QÂÅ÷s«{Ö4KåÒ£ „Ñ¥êÜT-íŠa(„W˜÷«(Áİœ]iúM`]>ÆLÏâq96HİÃ‹	qú«ë)¨ö€ÈåÉ3ÆÌş.ê»°»…©GVûØ¿§ò#ˆ:Ôj)U(`ß4p®n¾‘çÊ‰ğüöÁKD?xÙÀhør»¢8nĞ,ıK^ºáfk[IèYôl¤Ìu¼ô(öt†Y¹vwß>òÛb(ÕgßVòˆòÉ˜ÂÄ`ÃÓ’â«hP âÆ’˜å‚@DbæQ*D›øI~g†•.x_¤«äøÆdÉÜ'Éõİm¢û´IˆfQm„±¶­şGúË]Zó~r›„ã2}!v3
ä*Agx–¤×CAYÎTÁÀ,¢r*±zz½2 ü×›^Ç¢õÒÍ\ŠÑT•R9b7—>%ùY”ÖĞ1©†*tKOz2àh„*-AÀãG%E7—º&t£Œ/K7¾€®*£éq«ÓË»-RxnæZh¡u1ÿQûİ¨3l7ÕjUú”ªI5|©®.vv:Ø[‘Ãkß»‹=İ1â1³C‰ƒ„%³ˆÖª!­ğBéi·æ56Ê§PòÍÍùYÿÎN>ô._Ÿ·í€y—t¶ İ#1ï×ş_z¤rˆ[Q)
Îsj}		Ò|Ê‘?îcù/tƒèh·ÅÇP\6ó¦JNÈoùô õ
ID·»è¹Mim1\òvH¤^¥á–¸Şe¾—¿ŞIœ%Â#®äcHÁÙ«ÈêP˜Ü>ä})æ0ÖáOĞDuË3€~—oTâ^úæO5ĞMS"ã‘2§U˜»a%OLÜpüñy„üÈ\¼)û›Ü·óµ£©–¿ßkÌx­¼X·ÿÃVÛ<ÖnãÏûşû»¥ïÿoêsï¿ë»ë÷ßFKí¥^-Õt×U
ßË¬à*4-#7ªÒpéñğ—_fPzK‰Sé{¨vrMä-T»óo£¡jşÉÕGŒş¡ë&è?††)xŒÅc	6]»«?Êş³rıì{{ûMÎş±«¾¶ÿ?å¿ÿˆLô-–:0ÆÚä@IúıÀ0lW`NY¶gª“Úƒ¿™‡‹Á”"Öt=h¿?n÷0Un÷»íf¾ÔâáŞÙñH‚øëÅä7½X„ĞÌ5õ×ü¢6ğ÷íùe…Ñå8î!¿SÄ”u_)ˆËO èš”?
âGvˆÒ"zÕ)G" Zp‹É¬.I¥{mÑ½…2ñ^8ğ°D*ĞåÑO²·G>6ú·	6»ƒÌHY%ëS_CµşÔ^ûƒZÙÏc÷ÜÔ›şmªh†A½eõÇ³÷íÑâ«ƒÎû^«KèQ®¿„H}•Ñi{¥T(˜Çt½o°„pª³N@‚w&å4õGãO,¾’ĞÑÑÖÖ-Ÿ•ë_EN`e6“Ì†¥¶)»'9@¾'œşol9Z ¨)ôTBpÀûÎsº|É¹vBzÛé”Ô ¨›_aPÿk`¶!•.ÄšDâ;<v<®õ&§‚Şfì{^½¢7û¤y¨ÔÆŞN7Şoß‚úÅB%î@\Ùb±‡½&ıÃáprk_`I†pŠ”$ssÄ¹sËÅN1½˜¿ 6èüã%½äC{Èm’×øn
Qç«Wü{FÿÈÈsKùˆ^mpNùÏœ¼#Y|·S—RY„“¬B–<,DårY…n1º9]„|JoÊñª¸Bˆñ|9r-ÏÓ¸"úK¹Ùnp¨²Æë¼ÌEÒıê½[—êqlÚÇÚıbf÷¯!šöµ0AIØ(u—%à\„ÇPŞ3:ÚÓ'å˜oLòÚ÷:ã'3ğ’İë¨S¤Q…ÆîÚİD££óœ#I¡g“¡ÍÖYâº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûº­Ûºı·ÿÚæ 1 P  