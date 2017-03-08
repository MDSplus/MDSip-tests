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
� b�X�ks�62_�_��t��D�%�͍���J��,k,�i��hh�S$�?���. >�p��moN��Xv�@k�/��ma{��K�ov����������U���i�تo� 8��Z���B��i���m�M��[�'���[�FN������Z���[��+���'�Rvo���<��|5�LQ������:n7K�+�g�6e���ԊuNq�0�Ԑ��]�`�:}��~<�����^�rt͚8~0��ONS�����'*Kn�?9�&��s��L�ͩ��(`D\9>��g��c��C����k����;�,���'��=u;?��N�[���y�Wz��@ЅX�a*�Q��=y�4L�r�Eq=�Ff��
<*��۷�>y����5ۃR"#�V��qӱ�K8ם�u�RQ@49}VE�?'��U��Q�F5&��-�bh�i9	4)�ϼ[�_g����g�6�B+����4|�ỎcU24�P���8�n; C��RN�	�[$�<\9>�d��s��.wBOg�+����P5F~#�L]r�>�}���޴Y`<	�;e���Kft\�ψ]�'�-��Yh6u��%�Q�Mf:��C�z� ��&����-�XW�|�Ԡ_h���=�nbZ����Uh6�������::1n�|�-QŹ��%v��|������YӚ���F$�R0r��]�G:����A����������v�ị�g�3���9��N��m@l�J�P�����Y��E�T+_���/�j���i1_�ñ1�c8�R�V u �F�J���Ԏ�;�U�(jp��.�Ǝ�Ǝ�u�G���-�T%��PW�hk�ơ�!H�F�Lx$@��9ɪ�(8[5�Iaeո��H$�:⾂��\0��������7cOº�H%`|l�1�iP�ҦOAM���*� �<3`��ʦ��ft�M�L!)�?�	�G}�rA��O
�����W�V��?�	jِ#��S��xK)7�'5��jV����O�~3��PAm�e5���0��n40S�2�K�bu�����KÞ)���`,�ERQ��ԇj�4̙	��( �T"�/}�.�C�8�k���@�!�ƴxf�c ή-4��Z�^�3�~��v��Ύ�צp[(�x���`4h���>���z����*,����	fd��/��_:���htx�{�T���ʣR@Ɍ�w.h»N��̓EjI�T{䇺��c�
�g���0cʹB��aH$�a&��2�]b�0}����ێRp='ptL:�nB(��~���,�)�R��� �F���~~�u:O��Y���ٸ�d���w�m\���&+��s�*F|pli�~v�v���v~nC���m��ѹ8m���������9C͞!#���m7&��0R�|�v��_B������,���áw��k�mCI��*�l0 ʪEwl�	^D��z����G��l�����s
n2�@q�kL������d|���U�L�}Z�	�/��J�3�ra���8��g3�7ER�/�47�ML���T���?��'RЈ�Ku��;Ӳ��k6廁Ϭ1y[����B�RNC�	1$@)�&\�x�%2��v��~c�6���i:e�؅��H�0q,��/�/}İ5����~Tn���+��u+4P����4�2?�������bצ]EpƼ�B3���Nȉ�~�V��hT�Z����d$�a�_>Sv�Ä_*�~�0���=gʡǦ��o�f�bM(Y�3�i�!��X)NI�.8�m��=���Gۦ���?@�:5���w	�&�q��}A3��G;D�$=���	2&CRĐ����;��[�L�D��f����o�Ý�p�ꏆ'���a�w����6A���L��R߹�K]�iX������P�Θ�p����3�_a�5p�h�av���w,Z	�F{AZ6JQ(1nZP��9#伹L7��h��v�]��0	O�~��IhR���[�Τ��KƄ��L�g*��IڮcT�#A#�i�4�G��]z�X)=ǡp�\��I����xj"a����3���4Y�M��#?P���c*�M�M��
�<.k����zďV�Qhh�WE��#{ C�M�Â�r� ��
/����cOz4ǲM59f/F���TZ_¬<Z�֌�ϖ�v/9}�b��|�P���K!�*�Ր�:)`��_���sXW�2���Ԡ(����B��*v��Te��?�������X5yK�,: �a��N�b
,���6Tu؂%�L����=y֒2������2*UB�.Ts��N�5Av�D*+XMBdKD��I,し�SǀW��!�'��W�EY�FG忯��sTg�ȹ�����"vy�h�2���r�(�"�5D���Z�*���x���N���+�IT��"Y��Ӓ�w��,G
��I�+�����6G�&�H��P΅H9�.I2e��]*�]d4T�o�����O{+f����g�=���V�o,D~�'A�*�Ǜ3@�&iN�ً?'@���T��$�z�s��g���ß��a��T)EB�L<'����ȋ|��@�L��u�i\j�ξH�`�p��i�x �Dhס�N�­Q����s�{�4K�ң �ѥ��T-�a(�W���(�ݜ]i�M`]�>�L��q96H�Ë	q���)�������3���.껰���GV�ؿ��#�:�j)U(`�4p�n���ʉ�����KD?x��h�r��8n�,�K^��fk[I�Y�l��u��(�t�Y�vw�>��b(�g�V������`�����hP �ƒ��@Db�Q*D��I~g��.x_�����d��'����m���I�fQm������G��]Z�~r���2}!v3
�*Agx���CAY�T��,�r*�zz�2 �כ^Ǣ�ҍ�\��T�R9b7�>%�Y���1��*tKOz2�h�*-A��G%E7��&t��/K7���*��q��˻-Rxn�Zh�u1�Q�ݨ3l7�jU���I5|��.vv:�[��k����=�1�1�C���%��֪!��B�i��56ʧP����Y�ΏN>�._���y�t� �#1����_z�r��[Q�)
�sj}		�|��?�c�/t��h���P\6�JN�o�� �
ID����Mim1\�vH�^�ᖸ�e����I�%�#��cH�٫��P��>�})�0��O�Du�3�~�oT�^��O5�MS"�2�U��a%OL�p��y���\�)��ܷ󵣩���k�x��X���V�<�n�����������o�s�����FK��^-�t�U
�ˬ�*4-#7��p���_fPzK�S�{�vr�M�-T��o��j���G����&��?��)x��c	6]��?���r��{{�M�������?���L�-�:�0���@I���0�lW`NY�g��ڃ������"�t=h�?n�0Un���f�������H�����7�X���5����6����e��ѐ�8�!�SĔu_)��O �蚔?
�Gv��"z�)G"�Zp�ɬ.I�{mѽ�2�^8��D*���O��G>6��	6���HY%�S_C���^��Z��c�����m�h�A�e�ǳ���⫃��^�K�Q���H}��i{��T(��t�o��p��N@�w&�4�G�O,�������-���_EN`e6�̆��)�'9@�'��ol9Z �)�TBp���s�|ɹvBz��Ԡ��_aP�k`�!�.��D�;<v<��&���f�{^��7��y���ޞN7�o߂��B%�@\�b���&���prk_`I�p��$ssĹs��N1��� 6���%��C{��m���n
Q�W�{F�ȝ�sK��^mpN�Ϝ�#Y|�S��RY����B�<,D�rY�n1�9]�|Jo��B��|9r-���"�K��np�����E����[��ql����bf��!���0AI�(u�%�\��P�3:��'�oL���:�'3���S�Q�����D���#I��g����Y⺭ۺ�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ����� 1 P  