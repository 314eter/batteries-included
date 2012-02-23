open OUnit

module type Container = sig
  type 'a t
  val iter : ('a -> unit) -> 'a t -> unit
  val iter_right : ('a -> unit) -> 'a t -> unit
  val map : ('a -> 'b) -> 'a t -> 'b t
  val map_right : ('a -> 'b) -> 'a t -> 'b t
  val fold_left : ('acc -> 'a -> 'acc) -> 'acc -> 'a t -> 'acc
  val fold_right : ('acc -> 'a -> 'acc) -> 'acc -> 'a t -> 'acc
  val enum : 'a t -> 'a BatEnum.t
  val backwards : 'a t -> 'a BatEnum.t
  val of_enum : 'a BatEnum.t -> 'a t
  val of_backwards : 'a BatEnum.t -> 'a t
  val length : 'a t -> int
  val iteri : (int -> 'a -> unit) -> 'a t -> unit
  val mapi : (int -> 'a -> 'b) -> 'a t -> 'b t
  val exists : ('a -> bool) -> 'a t -> bool
  val for_all : ('a -> bool) -> 'a t -> bool
  val filter : ('a -> bool) -> 'a t -> 'a t
  val filter_map : ('a -> 'b option) -> 'a t -> 'b t
  val get : 'a t -> int -> 'a
  val append : 'a t -> 'a t -> 'a t
  val last : 'a t -> 'a
(* of_list, to_list, cons, snoc, tail, init, hd, sort, stable_sort, split_at, iter2, for_all2, take, drop, mem, find, find_map, reduce, max, min *)
end

exception NotImplemented

module ArrayContainer : Container = struct
  include Array
  include BatArray
  let map_right _ _ = raise NotImplemented
  let iter_right _ _ = raise NotImplemented
  let fold_right f acc t = fold_right (fun acc elt -> f elt acc) t acc
  let last _ = raise NotImplemented
end

module LazyListContainer : Container = struct
  include BatLazyList
  let map_right _ _ = raise NotImplemented
  let iter_right _ _ = raise NotImplemented
  let fold_right f acc t = fold_right (fun acc elt -> f elt acc) acc t
  let of_backwards _ = raise NotImplemented
  let backwards _ = raise NotImplemented
  let get = at
end

module DynArrayContainer : Container = struct
  include BatDynArray
  let of_backwards _ = raise NotImplemented
  let backwards _ = raise NotImplemented
  let iter_right _ _ = raise NotImplemented
  let map_right _ _ = raise NotImplemented
  let fold_right f acc t = fold_right (fun acc elt -> f elt acc) t acc
  let exists _ _ = raise NotImplemented
  let for_all _ _ = raise NotImplemented
  let append t1 t2 = let t1 = copy t1 in append t2 t1; t1
end

module DequeContainer : Container = struct
  include BatDeque
  let length = size
  let of_backwards _ = raise NotImplemented
  let backwards _ = raise NotImplemented
  let iter_right _ _ = raise NotImplemented
  let map_right _ _ = raise NotImplemented
  let fold_right f acc t = fold_right (fun acc elt -> f elt acc) t acc
  let exists _ _ = raise NotImplemented
  let for_all _ _ = raise NotImplemented
  let filter _ _ = raise NotImplemented
  let filter_map _ _ = raise NotImplemented
  let get _ _ = raise NotImplemented
  let last q = match rear q with None -> raise Exit | Some (_, e) -> e
end

module ListContainer : Container = struct
  include BatList
  let map_right _ _ = raise NotImplemented
  let iter_right _ _ = raise NotImplemented
  let fold_right f acc t = fold_right (fun acc elt -> f elt acc) t acc
  let get = at
end

module RefListContainer : Container = struct
  include BatRefList
  let map_right _ _ = raise NotImplemented
  let iter_right _ _ = raise NotImplemented
  let fold_right f acc t = fold_right (fun acc elt -> f elt acc) t acc
  let mapi _ _ = raise NotImplemented
  let iteri _ _ = raise NotImplemented
  let filter f l = let t = of_list (to_list l) in filter f t; t
  let filter_map _ _ = raise NotImplemented
  let get = Index.at_index
  let append _ _ = raise NotImplemented
end

module VectContainer : Container = struct
  include BatVect
  let map_right _ _ = raise NotImplemented
  let iter_right _ _ = raise NotImplemented
  let fold_right f acc t = fold_right (fun acc elt -> f elt acc) t acc
  let append = concat
end

module FingerTreeContainer : Container = struct
  include BatFingerTree
  let length = size
  let mapi _ _ = raise NotImplemented
  let iteri _ _ = raise NotImplemented
  let exists _ _ = raise NotImplemented
  let for_all _ _ = raise NotImplemented
  let filter _ _ = raise NotImplemented
  let filter_map _ _ = raise NotImplemented
  let last = last_exn
end

module SeqContainer : Container = struct
  include BatSeq
  let iter_right _ _ = raise NotImplemented
  let map_right _ _ = raise NotImplemented
  let fold_right f acc t = fold_right (fun acc elt -> f elt acc) t acc
  let backwards _ = raise NotImplemented
  let rec of_enum e =
    fun () ->
      let e = BatEnum.clone e in
      match BatEnum.get e with
      | None -> Nil
      | Some v -> Cons (v, of_enum e)
  let of_backwards _ = raise NotImplemented
  let mapi _ _ = raise NotImplemented
  let iteri _ _ = raise NotImplemented
  let get = at
end

module TestContainer(C : Container) = struct
  let n = 1000
  let a = Array.init n (fun i -> i)
  let rev_a = Array.init n (fun i -> n - 1 - i)
  let c = C.of_enum (BatArray.enum a)
  let rev_c = C.of_enum (BatArray.enum rev_a)

  let repeat_twice f =
    try
      (* repeating twice in case the structure mutates itself
         when doing operations on it *)
      f (); f ()
    with NotImplemented ->
      ()

  let () =
    repeat_twice (fun () -> assert (C.length c = n))

  let () =
    repeat_twice (fun () ->
      let i = ref (-1) in
      C.iter (fun elt -> incr i; assert (!i = elt)) c;
      assert (!i = n - 1)
    )

  let () =
    repeat_twice (fun () ->
      let i = ref (-1) in
      C.iteri (fun idx elt -> incr i; assert (!i = idx); assert (!i = elt)) c;
      assert (!i = n - 1)
    )

  let () =
    repeat_twice (fun () ->
      let i = ref n in
      C.iter_right (fun elt -> decr i; assert (!i = elt)) c;
      assert (!i = 0)
    )

  let () =
    repeat_twice (fun () ->
      let i = ref (-1) in
      let c = C.map (fun elt -> incr i; assert (!i = elt); elt + 1) c in
      let i = ref (-1) in
      (try C.iter (fun elt -> incr i; assert (!i + 1 = elt)) c;
      with NotImplemented -> failwith "map and not iter??");
      assert (!i = n - 1)
    )

  let () =
    repeat_twice (fun () ->
      let i = ref (-1) in
      let c = C.mapi (fun idx elt -> incr i; assert (!i = idx); assert (!i = elt); elt + 1) c in
      let i = ref (-1) in
      (try C.iteri (fun idx elt -> incr i; assert (!i = idx); assert (!i + 1 = elt)) c;
      with NotImplemented -> failwith "mapi and not iteri??");
      assert (!i = n - 1)
    )

  let () =
    repeat_twice (fun () ->
      let i = ref n in
      let c = C.map_right (fun elt -> decr i; assert (!i = elt); elt + 1) c in
      let i = ref n in
      (try C.iter_right (fun elt -> decr i; assert (!i + 1 = elt)) c;
      with NotImplemented -> failwith "map_right and not iter_right??");
      assert (!i = 0)
    )

  let () =
    repeat_twice (fun () ->
      let i = ref (-1) in
      let acc = 0 in
      let acc = C.fold_left (fun acc elt -> incr i; assert (!i = elt); acc + 1) acc c in
      assert (!i = n - 1);
      assert (acc = n)
    )

  let () =
    repeat_twice (fun () ->
      let i = ref n in
      let acc = 0 in
      let acc = C.fold_right (fun acc elt -> decr i; assert (!i = elt); acc + 1) acc c in
      assert (!i = 0);
      assert (acc = n)
    )

  let () =
    repeat_twice (fun () ->
      let e = C.enum c in
      for i = 0 to n / 2 - 1 do
        assert (i = BatEnum.get_exn e)
      done;
      let e' = BatEnum.clone e in
      assert_equal (BatEnum.count e) (BatEnum.count e');
      for i = n / 2 to n - 1 do
        assert (i = BatEnum.get_exn e && i = BatEnum.get_exn e')
      done;
      assert (BatEnum.is_empty e && BatEnum.is_empty e');
      assert (BatEnum.get e = None);
      assert (BatEnum.get e' = None)
    )

  let () =
    repeat_twice (fun () ->
      let e = C.backwards c in
      for i = 0 to n / 2 - 1 do
        assert (n - 1 - i = BatEnum.get_exn e)
      done;
      let e' = BatEnum.clone e in
      assert (BatEnum.count e = BatEnum.count e');
      for i = n / 2 to n - 1 do
        assert (n - 1 - i = BatEnum.get_exn e && n - 1 - i = BatEnum.get_exn e')
      done;
      assert (BatEnum.is_empty e && BatEnum.is_empty e');
      assert (BatEnum.get e = None);
      assert (BatEnum.get e' = None)
    )

  let () =
    repeat_twice (fun () ->
      let c = C.of_backwards (BatArray.enum rev_a) in
      repeat_twice (fun () -> assert (C.length c = n));
      repeat_twice (fun () ->
        let i = ref (-1) in
        C.iter (fun elt -> incr i; assert (!i = elt)) c;
        assert (!i = n - 1)
      )
    )

  let () =
    repeat_twice (fun () ->
      assert (C.for_all (fun elt -> elt < n) c);
      let i = ref (-1) in
      assert (not (C.for_all (fun elt -> incr i; elt < 200) c));
      assert (!i = 200);
    )

  let () =
    repeat_twice (fun () ->
      assert (not (C.exists (fun elt -> not (elt < n)) c));
      let i = ref (-1) in
      assert (C.exists (fun elt -> incr i; not (elt < 200)) c);
      assert (!i = 200);
    )

  let () =
    repeat_twice (fun () ->
      let i = ref (-1) in
      let c2 = C.filter (fun elt -> incr i; if not (elt = !i) then assert false; elt mod 2 = 0) c in
      let j = ref (-1) in
      C.iter (fun elt -> incr j; assert (!j * 2 = elt)) c2;
      assert (!i = n - 1);
      assert (!j = n / 2 - 1);
      (* iterating first to force the sequence of lazy
         sequence before checking the number of
         elements traversed *)
    )

  let () =
    repeat_twice (fun () ->
      let i = ref (-1) in
      let c2 = C.filter_map (fun elt -> incr i; assert (elt = !i); if elt mod 2 = 0 then Some (-(elt / 2)) else None) c in
      let j = ref (-1) in
      C.iter (fun elt -> incr j; assert (!j = -elt)) c2;
      assert (!i = n - 1);
      assert (!j = n / 2 - 1);
    )

  let () =
    repeat_twice (fun () ->
      assert (C.last c = n - 1);
      assert (try ignore (C.last (C.of_enum (BatEnum.empty ()))); false with _ -> true)
    )

  let () =
    repeat_twice (fun () ->
      let c = C.append c rev_c in
      assert (C.length c = n * 2);
      let i = ref (-1) in
      C.iter (fun elt -> incr i; assert (elt = min !i (2 * n - 1 - !i))) c
    )

  let () =
    repeat_twice (fun () ->
      for i = 0 to n - 1 do
        assert (C.get c i = i)
      done;
      assert (try ignore (C.get c (-1)); false with _ -> true);
      assert (try ignore (C.get c n); false with _ -> true);
    )

end

let tests = "Container" >::: [
  "List" >:: (fun () -> let module M = TestContainer(ListContainer) in ());
  "RefList" >:: (fun () -> let module M = TestContainer(RefListContainer) in ());
  "Seq" >:: (fun () -> let module M = TestContainer(SeqContainer) in ());
  "Vect" >:: (fun () -> let module M = TestContainer(VectContainer) in ());
  "FingerTree" >:: (fun () -> let module M = TestContainer(FingerTreeContainer) in ());
  "Array" >:: (fun () -> let module M = TestContainer(ArrayContainer) in ());
  "DynArray" >:: (fun () -> let module M = TestContainer(DynArrayContainer) in ());
  "Deque" >:: (fun () -> let module M = TestContainer(DequeContainer) in ());
  "Lazylist" >:: (fun () -> let module M = TestContainer(LazyListContainer) in ());
]
