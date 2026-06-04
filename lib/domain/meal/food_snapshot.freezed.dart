// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FoodSnapshot {

 String? get sourceFoodId; String get name; FoodKind get kind; FoodCategory get category; Grams get grams; double get protein; double get carbs; double get fats; double get kcal;
/// Create a copy of FoodSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodSnapshotCopyWith<FoodSnapshot> get copyWith => _$FoodSnapshotCopyWithImpl<FoodSnapshot>(this as FoodSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodSnapshot&&(identical(other.sourceFoodId, sourceFoodId) || other.sourceFoodId == sourceFoodId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.category, category) || other.category == category)&&(identical(other.grams, grams) || other.grams == grams)&&(identical(other.protein, protein) || other.protein == protein)&&(identical(other.carbs, carbs) || other.carbs == carbs)&&(identical(other.fats, fats) || other.fats == fats)&&(identical(other.kcal, kcal) || other.kcal == kcal));
}


@override
int get hashCode => Object.hash(runtimeType,sourceFoodId,name,kind,category,grams,protein,carbs,fats,kcal);

@override
String toString() {
  return 'FoodSnapshot(sourceFoodId: $sourceFoodId, name: $name, kind: $kind, category: $category, grams: $grams, protein: $protein, carbs: $carbs, fats: $fats, kcal: $kcal)';
}


}

/// @nodoc
abstract mixin class $FoodSnapshotCopyWith<$Res>  {
  factory $FoodSnapshotCopyWith(FoodSnapshot value, $Res Function(FoodSnapshot) _then) = _$FoodSnapshotCopyWithImpl;
@useResult
$Res call({
 String? sourceFoodId, String name, FoodKind kind, FoodCategory category, Grams grams, double protein, double carbs, double fats, double kcal
});




}
/// @nodoc
class _$FoodSnapshotCopyWithImpl<$Res>
    implements $FoodSnapshotCopyWith<$Res> {
  _$FoodSnapshotCopyWithImpl(this._self, this._then);

  final FoodSnapshot _self;
  final $Res Function(FoodSnapshot) _then;

/// Create a copy of FoodSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceFoodId = freezed,Object? name = null,Object? kind = null,Object? category = null,Object? grams = null,Object? protein = null,Object? carbs = null,Object? fats = null,Object? kcal = null,}) {
  return _then(_self.copyWith(
sourceFoodId: freezed == sourceFoodId ? _self.sourceFoodId : sourceFoodId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as FoodKind,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as FoodCategory,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as Grams,protein: null == protein ? _self.protein : protein // ignore: cast_nullable_to_non_nullable
as double,carbs: null == carbs ? _self.carbs : carbs // ignore: cast_nullable_to_non_nullable
as double,fats: null == fats ? _self.fats : fats // ignore: cast_nullable_to_non_nullable
as double,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodSnapshot].
extension FoodSnapshotPatterns on FoodSnapshot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodSnapshot() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _FoodSnapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _FoodSnapshot() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? sourceFoodId,  String name,  FoodKind kind,  FoodCategory category,  Grams grams,  double protein,  double carbs,  double fats,  double kcal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodSnapshot() when $default != null:
return $default(_that.sourceFoodId,_that.name,_that.kind,_that.category,_that.grams,_that.protein,_that.carbs,_that.fats,_that.kcal);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? sourceFoodId,  String name,  FoodKind kind,  FoodCategory category,  Grams grams,  double protein,  double carbs,  double fats,  double kcal)  $default,) {final _that = this;
switch (_that) {
case _FoodSnapshot():
return $default(_that.sourceFoodId,_that.name,_that.kind,_that.category,_that.grams,_that.protein,_that.carbs,_that.fats,_that.kcal);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? sourceFoodId,  String name,  FoodKind kind,  FoodCategory category,  Grams grams,  double protein,  double carbs,  double fats,  double kcal)?  $default,) {final _that = this;
switch (_that) {
case _FoodSnapshot() when $default != null:
return $default(_that.sourceFoodId,_that.name,_that.kind,_that.category,_that.grams,_that.protein,_that.carbs,_that.fats,_that.kcal);case _:
  return null;

}
}

}

/// @nodoc


class _FoodSnapshot extends FoodSnapshot {
  const _FoodSnapshot({this.sourceFoodId, required this.name, this.kind = FoodKind.product, required this.category, required this.grams, required this.protein, required this.carbs, required this.fats, required this.kcal}): assert(protein >= 0, 'protein must be >= 0'),assert(carbs >= 0, 'carbs must be >= 0'),assert(fats >= 0, 'fats must be >= 0'),assert(kcal >= 0, 'kcal must be >= 0'),super._();
  

@override final  String? sourceFoodId;
@override final  String name;
@override@JsonKey() final  FoodKind kind;
@override final  FoodCategory category;
@override final  Grams grams;
@override final  double protein;
@override final  double carbs;
@override final  double fats;
@override final  double kcal;

/// Create a copy of FoodSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodSnapshotCopyWith<_FoodSnapshot> get copyWith => __$FoodSnapshotCopyWithImpl<_FoodSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodSnapshot&&(identical(other.sourceFoodId, sourceFoodId) || other.sourceFoodId == sourceFoodId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.category, category) || other.category == category)&&(identical(other.grams, grams) || other.grams == grams)&&(identical(other.protein, protein) || other.protein == protein)&&(identical(other.carbs, carbs) || other.carbs == carbs)&&(identical(other.fats, fats) || other.fats == fats)&&(identical(other.kcal, kcal) || other.kcal == kcal));
}


@override
int get hashCode => Object.hash(runtimeType,sourceFoodId,name,kind,category,grams,protein,carbs,fats,kcal);

@override
String toString() {
  return 'FoodSnapshot(sourceFoodId: $sourceFoodId, name: $name, kind: $kind, category: $category, grams: $grams, protein: $protein, carbs: $carbs, fats: $fats, kcal: $kcal)';
}


}

/// @nodoc
abstract mixin class _$FoodSnapshotCopyWith<$Res> implements $FoodSnapshotCopyWith<$Res> {
  factory _$FoodSnapshotCopyWith(_FoodSnapshot value, $Res Function(_FoodSnapshot) _then) = __$FoodSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String? sourceFoodId, String name, FoodKind kind, FoodCategory category, Grams grams, double protein, double carbs, double fats, double kcal
});




}
/// @nodoc
class __$FoodSnapshotCopyWithImpl<$Res>
    implements _$FoodSnapshotCopyWith<$Res> {
  __$FoodSnapshotCopyWithImpl(this._self, this._then);

  final _FoodSnapshot _self;
  final $Res Function(_FoodSnapshot) _then;

/// Create a copy of FoodSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceFoodId = freezed,Object? name = null,Object? kind = null,Object? category = null,Object? grams = null,Object? protein = null,Object? carbs = null,Object? fats = null,Object? kcal = null,}) {
  return _then(_FoodSnapshot(
sourceFoodId: freezed == sourceFoodId ? _self.sourceFoodId : sourceFoodId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as FoodKind,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as FoodCategory,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as Grams,protein: null == protein ? _self.protein : protein // ignore: cast_nullable_to_non_nullable
as double,carbs: null == carbs ? _self.carbs : carbs // ignore: cast_nullable_to_non_nullable
as double,fats: null == fats ? _self.fats : fats // ignore: cast_nullable_to_non_nullable
as double,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
