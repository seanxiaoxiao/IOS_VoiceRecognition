/* iffscan - Simple AIFF/RIFF chunk scanner
 * Copyright (C) 2007  Josh Coalson
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#if HAVE_CONFIG_H
#  include <config.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if defined _MSC_VER || defined __MINGW32__
#include <sys/types.h> /* for off_t */
#if _MSC_VER <= 1600 /* @@@ [2G limit] */
#define fseeko fseek
#define ftello ftell
#endif
#endif
#include "foreign_metadata.h"

static FLAC__uint32 unpack32be_(const FLAC__byte *b)
{
	return ((FLAC__uint32)b[0]<<24) + ((FLAC__uint32)b[1]<<16) + ((FLAC__uint32)b[2]<<8) + (FLAC__uint32)b[3];
}

static FLAC__uint32 unpack32le_(const FLAC__byte *b)
{
	return (FLAC__uint32)b[0] + ((FLAC__uint32)b[1]<<8) + ((FLAC__uint32)b[2]<<16) + ((FLAC__uint32)b[3]<<24);
}

static FLAC__uint32 unpack32_(const FLAC__byte *b, foreign_block_type_t type)
{
	if(type == FOREIGN_BLOCK_TYPE__AIFF)
		return unpack32be_(b);
	else
		return unpack32le_(b);
}

