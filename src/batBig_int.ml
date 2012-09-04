(*
 * ExtInt32 - Extended Big integers
 * Copyright (C) 2007 Bluestorm <bluestorm dot dylc on-the-server gmail dot com>
 *               2008 David Teller
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version,
 * with the special exception on linking described in file LICENSE.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

open BatNumber

module BaseBig_int = struct
  open Big_int

  type t = big_int
  let zero = zero_big_int
  let one  = unit_big_int
  let succ = succ_big_int
  let pred = pred_big_int
  let neg  = minus_big_int
  let abs  = abs_big_int
  let add  = add_big_int
  let sub  = sub_big_int
  let mul  = mult_big_int
  let div  = div_big_int

  let modulo = mod_big_int
  let pow  = power_big_int_positive_big_int

  let to_string = string_of_big_int
  let of_string = big_int_of_string
  let to_int    = int_of_big_int
  let of_int    = big_int_of_int

  let compare   = compare_big_int

  let of_float f =
    try of_string (Printf.sprintf "%.0f" f)
    with Failure _ -> invalid_arg "batBig_int.of_float"
  (*$T of_float
    to_int (of_float 4.46) = 4
    to_int (of_float 4.56) = 5
    to_int (of_float (-4.46)) = -4
    to_int (of_float (-4.56)) = -5
    try ignore (of_float nan); false with Invalid_argument _ -> true
    try ignore (of_float (1. /. 0.)); false with Invalid_argument _ -> true
    try ignore (of_float (-1. /. 0.)); false with Invalid_argument _ -> true
  *)

  let to_float  = float_of_big_int
end

include Big_int
include MakeNumeric(BaseBig_int)

let print out t = BatIO.nwrite out (to_string t)
(*$T print
  BatIO.to_string print (of_int 456) = "456"
  BatIO.to_string print (power_int_positive_int 10 31) = "10000000000000000000000000000000"
  BatIO.to_string print (power_int_positive_int (-10) 31) = "-10000000000000000000000000000000"
*)
