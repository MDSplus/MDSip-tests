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
� ���X��W"Gre����큻��f���(��"O0���x�L#��������Uu�|
���$wG�D�����������o;�����������悔�7wv�5�_7��W;��ݯw_�ޫߡ�~�y �4������V��Y�5�Gɿ����������
v6��V�j�ڴ�����=�860�s<_À*S���Yw0�O:�R�Z�����"����33L/5������>vF��N��Vi���oY��YS�9���Y
���[Ce���������=3|���+'��A�|(�9O}!p�{�|!��Z�� �� ��|�D�5�ǽ�g�ǃ��<�e^��9�x�+0LE9�{�[��Y΍�(�g��x�,�\���k���ʹ�ݰ}(%2�j.70ۿ�ݙ�Pw�D�C�gU��s�s�JU j7����EW�"4m'�&��w�<���f�̀��&Zh\�����4|�q�J�� jQ��c�m`h��P�I:!z�Dq׎�$Y�܃�{��ĝ�ә��p�ߒcyUs`�7�4�%w�3�GFG����Yp�i�D�b,��q!?#v-�P��fg���Q�,F���t��c�z� ˶&����-�XW�|�̠��������Դ\\�7���jAu��� '�tt&b܌��D�E-��� ��V<�5�9+�kt@­#�*���`���?>�4v��i5�{{�����ǝo�?fp/dO�W�tjN���M+�B!��g���S���E_c �����*���5]1�9�(�jPRi4�D�>u@�ں�]�����B�a�xh��Q�}����rMUҚue���m��To�j��G�ݒ�������uc�V֍{!ߏ�Ar�c�+�̭%3IH����K�}���YX�1ɢ�σ<f?�P��9�ix�z�
7�{��	���vK�!ED�=DSHJ�O�bu�Q_�^�'��m'(�U�a��k�Z6��˩�fkK)7�Oj6�ӬX��[�2�v,�>F�Q��ps�
��<��h`��Ul�<��M'��=3�3���X����F��� i8|b&�[���Z�̾����a]� ��|�q4��3�<�pvo���ސ��5c�g�`����x�to
7����w��a����������?.Ta/g�L0#c�]���wF�������Ȥ�W�q�@��G�I>Ђ�^g�ۗٲH0k2Ĵ{쇺��d�k0��A'�i�˃����&��27��Ԣ�׮���䄮���ii2J�qj����M��Ǐ!�53�1#E^w�<��t��6�x��Ȅ���tG��.*�,#V=� �a&�v�ga���ڽ���wz��7ƋOg�A\�QI��h���h2��C\~,�v�CAR*����b���Nr)��5˲*!�HDR둻,5m�T��>�"1�ʂHwl��PQD����¾9��Vъk4-4�d|��7��%KT����:�'Pk$���Y��\�9�u���-�BQq��|��Ċ0���Q�1zl�`��H֧���p�`�<�J#6����M��0�ٔD>�&��^�j.��Ci'Đ �ݚpq8g�9�H˷hڙ�S�7�@��: }O�)}�.��K�� h���Qs�#��)��GΌ�a�+�kJ�u+4P����4��I3��4��nL��Lx��P���3�����Q��zhi^�F�y�����꙲�%4�V	 ��cN�=�����p�LʹŞP��3�i�!����R8�,�"]pB�@){N]�ئ!��������DɻI���/(c`&��q����P��v8�&A�dH�>�Q�� BW���� ��Q��,���-{�w<Nڃ��t�;=j��~j�}q�&(R;~**,����U���X�X���l&T�;�k��l~����WEd\(2̮��ߡ�� Ǣ�pl��e��#�Ђ�挐��e����6;��>Ը��d������!ř�W�ߛ�h�e��1s%[pfB���:VU584"NӤ�,8�����J�9�h�/�/��pf��3	�"6�h��d�7����T@5�L��7Q7�*h򸭩(R�?�zD��BCu�*�0��#bo�V�~��L�{v'���̷{��8�m���}1:�,�r��fg�yu�]`��}őv��#��>?��Ã�=9��c�g��L��e����R����h��2�=
��C���F���na�$�]����j�Ԅ�;�q`	I,����H�V�Q啪:�*>�=��^*Я��B+R�5��q���a5�����³(������ޢ��J�Չ�%O���jTW'�]!�����ԋ�B�P���g�������2�N�kr�4��]s����/�ݮ?H�u�/r�0�~����t
爋�1I��Fʅ)\�I��iKe����*��2�����53HM��3,^H�G�N��'"����L�� �I��0�a�N�y�$�0��4ɰ^����y����m�����i����	���L�Pd7>Ta(��r�&�4.5�_���s4�A��}2�b"���D'e!�ǔrp�}��w��R�4�0�T�۪�]3�^c���t�v�鷁Xt�:������0uE/&��c ��g�^�C>"�'�3����=�����$Y`���O�P/��T\T��};�H���	�F�+'�7R���׈~�����u��8n�*�]����^;I�Y����u�4<]`n����_��"J��_+yD����ab��9Iq��0)qcI�rI "1�(�
�-�$?�3�Z| ROr|�d�'����=�}ڤ
D�3����F�X�V�%���y?�M	��	���r���<
�	�����,g�``Q9�X=�_���M�c�~�2�I��R�R9Zn.}J�(��cNU�^�d��Uڂ�ǏJ�n.uM�F_�n|	]UFӓv��w[��"�,͵�B�b��·qw�9i�ժ�)U�*�R]]��t:��"��y�w{�2�f�	�,""Xr���K��ݙ7td(_I��8�+�8>�Կz{ѱ�]�	�t��x�F��iN�Ģj:S\���
��(��q��B7���)>F��7U����AS��at���،��%ϊ�a�AQn��]�{�Þ�Y��=b��|��o,��*�$&w y_�9��u��4Q���`����[�����+tӔ�x��i�nX�7�}�C�~���s�?�U<�;�ji��~c�3h�զ������v˨�~���_��|��xW�����y��{����~��RMw]����סi�Q��K�~X@�=eG�o���=6�^P�=}U���O��@���p�.���0�c�XW��6>鷲��\� �o6��r��l��l��w������z��X�*I����
���̴`�C{���p1�R�ğ.����'�>���A�3���Z<�??K�!����R+�J�-�ӆ-���⪢̕Y����?�K����Z�h�#��Q�C�:�HT�0c�%�t�-���P&��#�A��<��$����`+��-��=dF�*Y�������;���A�� S�l��"T=��z��w�;��W�ݏ�v�У�~��**��0K�P00Y�&�`	�Tg��5�L�i,�Ɵ�|%����lZ>+�9��aV��ؔ�I����&�����B��
x�EN������ E:%5(������mH��qÁ&�8�'�ǵ��T����}`ϛ7�f�4������r��{P?�X����U��פ'��\N���d���?�ܹ�b��^�_���衽F�Ɍk���B����^�ɉ�
b)��-�R�gN	>�,��-�[�,C�I�!�5,E�rY�n9�9[�|F���B�?��r�ڞ�=rE�W����Pe!��y�	����Cz�.��ĴO����Ѵo��J�F��,��Gx| 彠�;}Z�׍I^�Ag��^�u�4*���]��jt>��a$� �l2��&KܴM۴M۴M۴M۴M۴M۴M۴M۴���iʚO P  