// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MealTemplate {

 String get id; String get name; List<MealTag> get tags; List<ProductRef> get products;
/// Create a copy of MealTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealTemplateCopyWith<MealTemplate> get copyWith => _$MealTemplateCopyWithImpl<MealTemplate>(this as MealTemplate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.products, products));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(products));

@override
String toString() {
  return 'MealTemplate(id: $id, name: $name, tags: $tags, products: $products)';
}


}

/// @nodoc
abstract mixin class $MealTemplateCopyWith<$Res>  {
  factory $MealTemplateCopyWith(MealTemplate value, $Res Function(MealTemplate) _then) = _$MealTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<MealTag> tags, List<ProductRef> products
});




}
/// @nodoc
class _$MealTemplateCopyWithImpl<$Res>
    implements $MealTemplateCopyWith<$Res> {
  _$MealTemplateCopyWithImpl(this._self, this._then);

  final MealTemplate _self;
  final $Res Function(MealTemplate) _then;

/// Create a copy of MealTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tags = null,Object? products = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<MealTag>,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<ProductRef>,
  ));
}

}


/// Adds pattern-matching-related methods to [MealTemplate].
extension MealTemplatePatterns on MealTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealTemplate value)  $default,){
final _that = this;
switch (_that) {
case _MealTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _MealTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<MealTag> tags,  List<ProductRef> products)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealTemplate() when $default != null:
return $default(_that.id,_that.name,_that.tags,_that.products);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<MealTag> tags,  List<ProductRef> products)  $default,) {final _that = this;
switch (_that) {
case _MealTemplate():
return $default(_that.id,_that.name,_that.tags,_that.products);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<MealTag> tags,  List<ProductRef> products)?  $default,) {final _that = this;
switch (_that) {
case _MealTemplate() when $default != null:
return $default(_that.id,_that.name,_that.tags,_that.products);case _:
  return null;

}
}

}

/// @nodoc


class _MealTemplate extends MealTemplate {
  const _MealTemplate({required this.id, required this.name, final  List<MealTag> tags = const <MealTag>[], final  List<ProductRef> products = const <ProductRef>[]}): _tags = tags,_products = products,super._();
  

@override final  String id;
@override final  String name;
 final  List<MealTag> _tags;
@override@JsonKey() List<MealTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<ProductRef> _products;
@override@JsonKey() List<ProductRef> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}


/// Create a copy of MealTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealTemplateCopyWith<_MealTemplate> get copyWith => __$MealTemplateCopyWithImpl<_MealTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._products, _products));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_products));

@override
String toString() {
  return 'MealTemplate(id: $id, name: $name, tags: $tags, products: $products)';
}


}

/// @nodoc
abstract mixin class _$MealTemplateCopyWith<$Res> implements $MealTemplateCopyWith<$Res> {
  factory _$MealTemplateCopyWith(_MealTemplate value, $Res Function(_MealTemplate) _then) = __$MealTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<MealTag> tags, List<ProductRef> products
});




}
/// @nodoc
class __$MealTemplateCopyWithImpl<$Res>
    implements _$MealTemplateCopyWith<$Res> {
  __$MealTemplateCopyWithImpl(this._self, this._then);

  final _MealTemplate _self;
  final $Res Function(_MealTemplate) _then;

/// Create a copy of MealTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tags = null,Object? products = null,}) {
  return _then(_MealTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<MealTag>,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<ProductRef>,
  ));
}


}

// dart format on
