// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MealProduct {

 String? get sourceProductId; String get name; ProductCategory get category; double get protein; double get carbs; double get fats; double? get kcalOverride; Grams get grams; bool get checked;
/// Create a copy of MealProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealProductCopyWith<MealProduct> get copyWith => _$MealProductCopyWithImpl<MealProduct>(this as MealProduct, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealProduct&&(identical(other.sourceProductId, sourceProductId) || other.sourceProductId == sourceProductId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.protein, protein) || other.protein == protein)&&(identical(other.carbs, carbs) || other.carbs == carbs)&&(identical(other.fats, fats) || other.fats == fats)&&(identical(other.kcalOverride, kcalOverride) || other.kcalOverride == kcalOverride)&&(identical(other.grams, grams) || other.grams == grams)&&(identical(other.checked, checked) || other.checked == checked));
}


@override
int get hashCode => Object.hash(runtimeType,sourceProductId,name,category,protein,carbs,fats,kcalOverride,grams,checked);

@override
String toString() {
  return 'MealProduct(sourceProductId: $sourceProductId, name: $name, category: $category, protein: $protein, carbs: $carbs, fats: $fats, kcalOverride: $kcalOverride, grams: $grams, checked: $checked)';
}


}

/// @nodoc
abstract mixin class $MealProductCopyWith<$Res>  {
  factory $MealProductCopyWith(MealProduct value, $Res Function(MealProduct) _then) = _$MealProductCopyWithImpl;
@useResult
$Res call({
 String? sourceProductId, String name, ProductCategory category, double protein, double carbs, double fats, double? kcalOverride, Grams grams, bool checked
});




}
/// @nodoc
class _$MealProductCopyWithImpl<$Res>
    implements $MealProductCopyWith<$Res> {
  _$MealProductCopyWithImpl(this._self, this._then);

  final MealProduct _self;
  final $Res Function(MealProduct) _then;

/// Create a copy of MealProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceProductId = freezed,Object? name = null,Object? category = null,Object? protein = null,Object? carbs = null,Object? fats = null,Object? kcalOverride = freezed,Object? grams = null,Object? checked = null,}) {
  return _then(_self.copyWith(
sourceProductId: freezed == sourceProductId ? _self.sourceProductId : sourceProductId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ProductCategory,protein: null == protein ? _self.protein : protein // ignore: cast_nullable_to_non_nullable
as double,carbs: null == carbs ? _self.carbs : carbs // ignore: cast_nullable_to_non_nullable
as double,fats: null == fats ? _self.fats : fats // ignore: cast_nullable_to_non_nullable
as double,kcalOverride: freezed == kcalOverride ? _self.kcalOverride : kcalOverride // ignore: cast_nullable_to_non_nullable
as double?,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as Grams,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MealProduct].
extension MealProductPatterns on MealProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealProduct value)  $default,){
final _that = this;
switch (_that) {
case _MealProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealProduct value)?  $default,){
final _that = this;
switch (_that) {
case _MealProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? sourceProductId,  String name,  ProductCategory category,  double protein,  double carbs,  double fats,  double? kcalOverride,  Grams grams,  bool checked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealProduct() when $default != null:
return $default(_that.sourceProductId,_that.name,_that.category,_that.protein,_that.carbs,_that.fats,_that.kcalOverride,_that.grams,_that.checked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? sourceProductId,  String name,  ProductCategory category,  double protein,  double carbs,  double fats,  double? kcalOverride,  Grams grams,  bool checked)  $default,) {final _that = this;
switch (_that) {
case _MealProduct():
return $default(_that.sourceProductId,_that.name,_that.category,_that.protein,_that.carbs,_that.fats,_that.kcalOverride,_that.grams,_that.checked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? sourceProductId,  String name,  ProductCategory category,  double protein,  double carbs,  double fats,  double? kcalOverride,  Grams grams,  bool checked)?  $default,) {final _that = this;
switch (_that) {
case _MealProduct() when $default != null:
return $default(_that.sourceProductId,_that.name,_that.category,_that.protein,_that.carbs,_that.fats,_that.kcalOverride,_that.grams,_that.checked);case _:
  return null;

}
}

}

/// @nodoc


class _MealProduct extends MealProduct {
  const _MealProduct({this.sourceProductId, required this.name, required this.category, required this.protein, required this.carbs, required this.fats, this.kcalOverride, required this.grams, this.checked = false}): assert(protein >= 0, 'protein must be >= 0'),assert(carbs >= 0, 'carbs must be >= 0'),assert(fats >= 0, 'fats must be >= 0'),super._();
  

@override final  String? sourceProductId;
@override final  String name;
@override final  ProductCategory category;
@override final  double protein;
@override final  double carbs;
@override final  double fats;
@override final  double? kcalOverride;
@override final  Grams grams;
@override@JsonKey() final  bool checked;

/// Create a copy of MealProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealProductCopyWith<_MealProduct> get copyWith => __$MealProductCopyWithImpl<_MealProduct>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealProduct&&(identical(other.sourceProductId, sourceProductId) || other.sourceProductId == sourceProductId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.protein, protein) || other.protein == protein)&&(identical(other.carbs, carbs) || other.carbs == carbs)&&(identical(other.fats, fats) || other.fats == fats)&&(identical(other.kcalOverride, kcalOverride) || other.kcalOverride == kcalOverride)&&(identical(other.grams, grams) || other.grams == grams)&&(identical(other.checked, checked) || other.checked == checked));
}


@override
int get hashCode => Object.hash(runtimeType,sourceProductId,name,category,protein,carbs,fats,kcalOverride,grams,checked);

@override
String toString() {
  return 'MealProduct(sourceProductId: $sourceProductId, name: $name, category: $category, protein: $protein, carbs: $carbs, fats: $fats, kcalOverride: $kcalOverride, grams: $grams, checked: $checked)';
}


}

/// @nodoc
abstract mixin class _$MealProductCopyWith<$Res> implements $MealProductCopyWith<$Res> {
  factory _$MealProductCopyWith(_MealProduct value, $Res Function(_MealProduct) _then) = __$MealProductCopyWithImpl;
@override @useResult
$Res call({
 String? sourceProductId, String name, ProductCategory category, double protein, double carbs, double fats, double? kcalOverride, Grams grams, bool checked
});




}
/// @nodoc
class __$MealProductCopyWithImpl<$Res>
    implements _$MealProductCopyWith<$Res> {
  __$MealProductCopyWithImpl(this._self, this._then);

  final _MealProduct _self;
  final $Res Function(_MealProduct) _then;

/// Create a copy of MealProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceProductId = freezed,Object? name = null,Object? category = null,Object? protein = null,Object? carbs = null,Object? fats = null,Object? kcalOverride = freezed,Object? grams = null,Object? checked = null,}) {
  return _then(_MealProduct(
sourceProductId: freezed == sourceProductId ? _self.sourceProductId : sourceProductId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ProductCategory,protein: null == protein ? _self.protein : protein // ignore: cast_nullable_to_non_nullable
as double,carbs: null == carbs ? _self.carbs : carbs // ignore: cast_nullable_to_non_nullable
as double,fats: null == fats ? _self.fats : fats // ignore: cast_nullable_to_non_nullable
as double,kcalOverride: freezed == kcalOverride ? _self.kcalOverride : kcalOverride // ignore: cast_nullable_to_non_nullable
as double?,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as Grams,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
