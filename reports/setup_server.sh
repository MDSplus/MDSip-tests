#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1452419944"
MD5="8da94b5a7ff0f180763ea5f311dbadbf"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4607"
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
	echo Date of packaging: Tue May 23 11:52:42 CEST 2017
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
� j$Y�\ySǶ���O�t}%l	$Ar[�( ;�+@� NP��LK3[�gX.�w�tώ�IL��jN%�t���r�^N��;�^�v�~���ߍ�w��Cz�h5���Vc��j����������g���J�4�*�q����R}�Q�w�l�wɿ�}���������B�/N[��uk��$i���#�E���.�@3H�J���7�8�t���Xa�RLJ��\�Fǽs��t7�%��v=r�9�ؽ�|6�h��_m�Vcf3o���`�:h��%����1��w<��15�;#�"s��x8�_E;�_ �����E�gs��i���g��<��~:��6t.~��}|P~ʀ� ta)O�%���}lk�b�SI�W��ьN�J�$U�����{�A�dʔ�r,#R��+��t�b7�J�Mt�F��� +��	�>g_j5��JB��x3�LI�4v'F��0��Q��~z6S�3���F'�ox\�Ո̱m���)4
90�v)$[�O�9e$3��І��h����{�TWw���*��2��`Ĳ#T���ox$E")�=���@��ݢ��#�[�-��m�dk����U�4������Q�p��
#���:!��&�%	�,kk�8��(QM��������nPruޠ!�v�Զ��yG4;����LD��;�X�e���R������=�5�9Kr�h� ��.U�����S�����h���n������k5ח<��t�1U�s}����3}�o "��J�R�7W�B���U�`��0��j���yQ���f[0�rE�[�fx�AP���b����&r�Rm�*aur	�.��Ll��7�>���-�e)���!M�ր&���z#G�f|& �y�N���,8_����ʪ|���	t]��
^s{AM�ѩ	^z���ҵX�R؂�Ͱ�K��P@)�:�̟.i`�Nbv �Ԝi#E̓�C�����4r`�9��X3�.v�)Vc��#������cV�rv��\���u�n�+W	��9�4�1'��̇���+�������{��T�����eO�ߡ9�|�a���F��9o?�:���C�{�$^U�|�i>	�Lg�
L=/��sD��i�|=��T:��\xk�o�,'��3�V>��HL�ۜ{W�(_��	nM�7����s�"��h�K�REE�/����Ә�����EpEv�	n鍽�?��-�����z�ў��UoG��#�X ��|��'Ou�Ln��?����n!ń�<ɜtQOG7u<d�6 ��>ی@j�^K����� ��XG�P!�׀����;O5�gMt�8���k�K�X/h3�n�7�.�����¾I�T`�<���z�Ѱ{�K�|t~yz�;�8��e��]�41e�]��;�^���N?�e)8ZdғTɌ�G��qK�|����z��:8�x(Z�ŶF�WU�X����A�8�L��]�ŠHp�t�8�Tl ̾��H�-[*9��٪m$��@���-�zܥv�]�J���e���T�e����iH%<�P,�S�wy���.��#�-8g]��lTE�gNe�ҙ��v�~�.9=;��;��op��;I*�,r�a��%h�b���̤��$}u��bG0A�%��[\>��4����#1��ܮuR���w�`60!gêmYT��-(�Vp����XQ���g
�kN��@q��z!��#eq�*�ǨU���^�q�7l��J�3�/�-2�dID�xl�f�\`p%X����ԴaI˗a�G����:��y@$��n��Oa�nL�����_q@Ȏ�+�;f� R�	��\���X��x����6��a��**�gB��G��-����7�/~Dغ�Jzd�x<)��tK5|���#qEŕ��¨�;6~L������=�I�A��f���F�ǰ�O]=]��MZJ\0R`�_^S�����*`<UJ5T�k�=�]��2|0�}���D���g����(��+�۷4���W�aS`���o5u/���;�Ċ�u4. cBu�@����a��G,�� #6(E��r� �+0��(/��1���`�[�xo�9�Fg���Q�O�g:��mD���0q0���s�t�a�����F�G�QS�Ro��p�X<�+_a�5p�(0`V��l
#���{^HQ(1XP<�#�ms��Cc����un�(��(�%�lP�� G��e�:4�2,��a���`�B�Q���*l���X�G+�d��K�d��R����A�s��x���	zl��X/��u�10Y�M�އ~����L0���nj�U��[3��@�|����w
���U1���#{$��[��>��ˌ����Nx�m�w?��#�n��e��0�[N,ˣ�.+��=����;Kb���٘Jv�FT�"��SV#є��D,e&��<CH�8�����Q�M��<Xw3l?� ����in���9��L�"���Zd/�^0Y-و���L�d->'� Ms�S1���d�d=z���`���l��r�Sq���TTd-:Y�NED֣'yZ���l��˃NJo�����R�\�|���T�c-:�Xϛ�f:���{l�n��<�OG<���\���v�E�b��N���s���~}��e!\����rOd�f�rx�L��8]�%��C������}\j�U�L	�#XTTQ��?Z���]��쐗T0�qQ��l$Κ��
���O����S�u~-˄,8�G-u��9����j�e	�pC�Y,k?7m��yX���^�Z~¾̇�2�\�A��XÊs'~}��pQsy !րe�<"�2!�� #.�F'���:@����6Y�a0���w�+bE2��:���џ���HXexq6��!ƿ(�h�{�#�F{�(�+!R���L���9E����ì�;�)l�|�r���@S�t��Q��9���ȯ�������>3@����1�W̉��M|�x<Ѱ^0��G�A���s����E�ۖ��7sm:s|q6�H���Qmk�O}W႐��C��8�{tA���ɐl�B��:8)�~��.�_:���]���#�]j�m�P��ҡ?6uO	����XQo=�3��S��y��/>D�P}�ؠ+�5�9A��8k��5t�4���.,]xay �2�4H�$��LJ��K�1����7�p���o&���P��uf�׭�d;^����z7|�jm7�z=P�p/?�1��/D��%�|��H�1�g5[0x���dK�d×7(ES�yr�7��,LD(f>K%&�6|����J�N,W��MВ�O���#x�ܧ����pbF������=�s|���m^��n����t���
���P��T��Y�ʉ����·��d?�o�<[b�e�\	��Y>��pY��bT����`�2vA�ᣚ��Y��|�_�o���̦'��i�m��f�Z,�!�?�~�.�'m�V|JM�8F�!/vv*^Z0B��}���E���Z~P��LL��^K�ʝ>ŀk��.x�uu9�!W�g�No�^u-��7_	�#6�ձ8�_~��>��XDjSp�Q�z���>�c�_��Ѷ�ǅ�p�IZ�~���a⽛<o����jb�"\�JM&ާ%qK\�2��߉�Β?�f�8�d�7���ɽ#Y_
k���cG���+B�]ޮF�����ƅ��ʜTa,3q���s�X������o��!�;�j��ǃ术��W}C��O�[�[�}���������C����ݽ���_A���}��8R��`����ere�.?��뜔��r��#��2�`��=���6�Ԍ���?��fG�3��"I�q���.�Q^/����Z�����`��V뇌��Z�������#4�����1�g�R��<M��I�n�t��x�L�G���E0iV�xGn��x�=�l�d��a=�e�^��Ȑ�;�t~��� շ�
ن��n�x)��v��m'XH��J�Z��.~]�>�Y�X��&AN�{w��TV�TK$�S�x/�q)����'rp�>�l{��M,zOR9�O~Kj��D>�~��ﲥOm�m�	2�*�����ˏ��.�������>W�K�4�q�w�iN���k/j4f�Hl Hp�Τ�,��a���Wc>*ؚG��h��؉R���Bj�Ô���	g�M[��6h
^�-�iW]�᭶}�u�T�Aa2,`�[B--P�0:�)A!>���Z�s.��}�> ���7P�@�����O�O �x�e2؂A��?8*7މRA�����uu��3݅DQ���$����1 {����h�Ja�7�{�?��ȶ ��1�w��-�f������Jԕ��Pɪ�A�rYU8��⺹��9޲�D��
!���˰븮���-mM��Q!��Y�	����C|Q�ǉn�(�#Z���վ�#8	��J |��� �9���J�nX�uT��K�k���N�F����3�3:,]�����6/V�TPATPATPATPATPATPATPATPATPAT��?�_���m x  