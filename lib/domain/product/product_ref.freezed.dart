// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_ref.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductRef {

 String get productId; Grams get grams;
/// Create a copy of ProductRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductRefCopyWith<ProductRef> get copyWith => _$ProductRefCopyWithImpl<ProductRef>(this as ProductRef, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductRef&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.grams, grams) || other.grams == grams));
}


@override
int get hashCode => Object.hash(runtimeType,productId,grams);

@override
String toString() {
  return 'ProductRef(productId: $productId, grams: $grams)';
}


}

/// @nodoc
abstract mixin class $ProductRefCopyWith<$Res>  {
  factory $ProductRefCopyWith(ProductRef value, $Res Function(ProductRef) _then) = _$ProductRefCopyWithImpl;
@useResult
$Res call({
 String productId, Grams grams
});




}
/// @nodoc
class _$ProductRefCopyWithImpl<$Res>
    implements $ProductRefCopyWith<$Res> {
  _$ProductRefCopyWithImpl(this._self, this._then);

  final ProductRef _self;
  final $Res Function(ProductRef) _then;

/// Create a copy of ProductRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? grams = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as Grams,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductRef].
extension ProductRefPatterns on ProductRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductRef value)  $default,){
final _that = this;
switch (_that) {
case _ProductRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductRef value)?  $default,){
final _that = this;
switch (_that) {
case _ProductRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  Grams grams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductRef() when $default != null:
return $default(_that.productId,_that.grams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  Grams grams)  $default,) {final _that = this;
switch (_that) {
case _ProductRef():
return $default(_that.productId,_that.grams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  Grams grams)?  $default,) {final _that = this;
switch (_that) {
case _ProductRef() when $default != null:
return $default(_that.productId,_that.grams);case _:
  return null;

}
}

}

/// @nodoc


class _ProductRef extends ProductRef {
  const _ProductRef({required this.productId, required this.grams}): super._();
  

@override final  String productId;
@override final  Grams grams;

/// Create a copy of ProductRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductRefCopyWith<_ProductRef> get copyWith => __$ProductRefCopyWithImpl<_ProductRef>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductRef&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.grams, grams) || other.grams == grams));
}


@override
int get hashCode => Object.hash(runtimeType,productId,grams);

@override
String toString() {
  return 'ProductRef(productId: $productId, grams: $grams)';
}


}

/// @nodoc
abstract mixin class _$ProductRefCopyWith<$Res> implements $ProductRefCopyWith<$Res> {
  factory _$ProductRefCopyWith(_ProductRef value, $Res Function(_ProductRef) _then) = __$ProductRefCopyWithImpl;
@override @useResult
$Res call({
 String productId, Grams grams
});




}
/// @nodoc
class __$ProductRefCopyWithImpl<$Res>
    implements _$ProductRefCopyWith<$Res> {
  __$ProductRefCopyWithImpl(this._self, this._then);

  final _ProductRef _self;
  final $Res Function(_ProductRef) _then;

/// Create a copy of ProductRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? grams = null,}) {
  return _then(_ProductRef(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as Grams,
  ));
}


}

// dart format on
