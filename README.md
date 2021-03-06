AlexQuinlivan/Helium
=========================
An Android-like view inflation and bucketed resource library for iOS. 


Note
----
This project is in its very infant stages (it doesn't yet do what it says) and is only intended (at this point) as a side project to explore a bit more of the Objective-C runtime before throwing it away completely. That being said, it does have certain goals [(see Goals)](#goals). 


Goals
-----
- A drop in view language that mimics similar attributes from android layouts, but, allows use without the need for subclassing library views or having the libraries views clutter up the view hierarchy
- Custom view attributes
- A view binder like [ButterKnife](https://github.com/JakeWharton/butterknife) so arbitrary objects can have views bound into them from a root view. (Similar to an IBOutlet)
- A collection of predefined layouts (linear/frame/relative/etc...) that can be assigned to any view
- Custom layouts
- A resources pattern that loads the correct view/string/dimension for the current device config


Installation
------------
Helium is (not yet) available through the [CocoaPods](http://cocoapods.org) repo. However, to install
it directly from this repo, simply add the following line to your Podfile:
```ruby
pod 'Helium', :git => 'https://github.com/AlexQuinlivan/Helium.git'
```


Usage
-----
The api for this is changing very rapidly, the [example project](https://github.com/AlexQuinlivan/Helium/tree/master/Example) should be using the most up-to-date version of where this library is heading.

todo: Actually make this relevant and up to date, using the best practices as well. (Maybe it wont even end up in the final README)

#### An example view xml file
```xml
<?xml version="1.0" encoding="utf-8" ?>
<UIView xmlns:helium="http://quinlivan.co.nz/helium"
    helium:id="example_id"
    helium:layout_width="match_parent"
    helium:layout_height="match_parent"
    helium:layout="@layout/frame"
    background_color="#F00">
    <UIView
        helium:layout_width="200"
        helium:layout_height="200"
        helium:layout_gravity="center_vertical|right"
        background_color="#ABCDEF" />
</UIView>
```

#### An example view controller implementation
```objc
@interface ABCViewController : HLMViewController
@property (nonatomic, weak) UIView *example;
@end

@implementation ABCViewController
BIND_VIEW_OPTIONAL(example, example_id)

-(NSString *) layoutResource {
    return @"@view/example_view";
}

@end
```


Similar projects
----------------
[iDroidLayout](https://github.com/tomquist/iDroidLayout) - https://github.com/tomquist/iDroidLayout


License
-------

    Copyright 2015 Alex Quinlivan
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    
