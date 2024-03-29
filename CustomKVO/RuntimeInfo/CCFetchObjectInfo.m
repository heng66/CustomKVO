//
//  CCFetchObjectInfo.m
//  CustomKVO
//
//  Created by chenqg on 2019/6/20.
//  Copyright © 2019年 helanzhu. All rights reserved.
//


#import "CCFetchObjectInfo.h"

@implementation CCFetchObjectInfo
/*
 *1.根据类名获取类
 gdb_objc_realized_classes表中根据key,查询value
 表中含有一系列的MapPair，顺序获取每个MapPair
 typedef struct _MapPair {
 const void    *key;
 const void    *value;
 } MapPair;
 */
+ (Class)fetchClass:(NSString *)clsName{
    const char * name = [clsName UTF8String];
    return objc_getClass(name);
}

/*
 *2.根据类获取类名
 class_rw_t结构体中有demangledName，这就是类名
 */
+ (NSString *)fetchClassName:(Class)cls{
    const char * name = class_getName(cls);
    return [NSString stringWithUTF8String:name];
}

/*
 *3.获取成员变量
 class_ro_t结构体中有ivar_list_t，遍历获取Ivar
 ivar_getName:ivar->name
 ivar_getTypeEncoding:ivar->type
 */
+ (NSArray *)fetchIvarList:(Class)cls{
    unsigned int outCount = 0;
    Ivar *ivarList = class_copyIvarList(cls, &outCount);
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:outCount];
    for (unsigned int i = 0; i < outCount; i++) {
        Ivar ivar = ivarList[i];
        const char *ivarName = ivar_getName(ivar);
        const char *ivarType = ivar_getTypeEncoding(ivar);
        NSDictionary *ivarDic = @{@"ivarName":[NSString stringWithUTF8String:ivarName],
                                  @"ivarType":[NSString stringWithUTF8String:ivarType]};
        [mutableArray addObject:ivarDic];
    }
    free(ivarList);
    return [NSArray arrayWithArray:mutableArray];
}

/*
 *4.获取成员属性
 class_rw_t结构体中有properties，遍历获取property_t，objc_property_t是property_t的别名
 property_getName:prop->name
 property_getAttributes:prop->attributes
 */
+ (NSArray *)fetchPropertyList:(Class)cls{
    unsigned int outCount = 0;
    objc_property_t *propertyList = class_copyPropertyList(cls, &outCount);
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:outCount];
    for (unsigned int i = 0; i < outCount; i++) {
        objc_property_t property = propertyList[i];
        const char *propertyName = property_getName(property);
        const char *propertyAttributes = property_getAttributes(property);
        NSDictionary *propertyDic = @{@"propertyName":[NSString stringWithUTF8String:propertyName],
                                      @"propertyAttributes":[NSString stringWithUTF8String:propertyAttributes]};
        [mutableArray addObject:propertyDic];
    }
    free(propertyList);
    return [NSArray arrayWithArray:mutableArray];
}

/*
 *5.获取类的实例方法
 class_rw_t结构体中有methods，遍历获取Method
 method_getName:m->name
 method_getTypeEncoding:m->types
 */
+ (NSArray *)fetchMethodList:(Class)cls{
    unsigned int outCount = 0;
    Method *methodList = class_copyMethodList(cls, &outCount);
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:outCount];
    for (unsigned int i = 0; i < outCount; i++) {
        Method method = methodList[i];
        SEL methodName = method_getName(method);
        const char *methodType = method_getTypeEncoding(method);
        NSDictionary *methodDic = @{@"methodName":NSStringFromSelector(methodName),
                                    @"methodType":[NSString stringWithUTF8String:methodType]};
        [mutableArray addObject:methodDic];
    }
    free(methodList);
    return [NSArray arrayWithArray:mutableArray];
}

/*
 *6.获取协议列表
 class_rw_t结构体中有protocols，遍历获取Protocol
 method_getName:protocol_t结构体中有mangledName，Protocol强转成了protocol_t
 */
+ (NSArray *)fechProtocolList:(Class)cls{
    unsigned int outCount = 0;
    __unsafe_unretained Protocol **potocolList = class_copyProtocolList(cls, &outCount);
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:outCount];
    for (unsigned int i = 0; i < outCount; i++) {
        Protocol *protocol = potocolList[i];
        const char *protocolName = protocol_getName(protocol);
        [mutableArray addObject:[NSString stringWithUTF8String:protocolName]];
    }
    free(potocolList);
    return [NSArray arrayWithArray:mutableArray];
}

/*
 *7.动态添加方法
 (1)若待添加的方法已存在，若添加，则不替换，直接返回旧的实现；若替换，则替换掉原有方法实现，返回旧的实现
 (2)若待添加的方法不存在，class_rw_t中的methods添加新方法
 旧的list往后移动addedCount
 memmove(array()->lists + addedCount, array()->lists,oldCount * sizeof(array()->lists[0]));
 新的list添加到前面addedCount的区域
 memcpy(array()->lists, addedLists,addedCount * sizeof(array()->lists[0]));
 */
+ (void)addMethod:(Class)cls methodName:(SEL)method methodClass:(Class)methodClass methodIMP:(SEL)methodIMP{
    Method ccMethod = class_getInstanceMethod(methodClass, methodIMP);
    IMP ccMethodIMP = method_getImplementation(ccMethod);
    const char *types = method_getTypeEncoding(ccMethod);
    class_addMethod(cls, method, ccMethodIMP, types);
}

/*
 *8.动态交换方法
 IMP method1_imp = method1->imp;
 method1->imp = method2->imp;
 method2->imp = method1_imp;
 */
+ (void)exchangeMethod:(Class)cls firstMethod:(SEL)firstMethod secondMethod:(SEL)secondMethod
{
    Method method1 = class_getInstanceMethod(cls, firstMethod);
    Method method2 = class_getInstanceMethod(cls, secondMethod);
    method_exchangeImplementations(method1, method2);
}
@end

