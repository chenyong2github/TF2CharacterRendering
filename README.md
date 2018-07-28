# TF2CharacterRendering
TF2角色的卡通化渲染算法可概括为由视角无关（view independent）和视角相关（view dependent）两部分光照计算构成。视角无关部分由环境光加上风格化的漫反射光照构成，视角相关部分由自定义的Phong高光和边缘光（rim light）构成。上述的所有光照计算均为逐像素的光照计算，绝大部分材质属性包括法线、高光指数和遮罩等都取自贴图......
http://blog.chenyong.me/2017/04/19/tf2/

Screenshots:

![](https://raw.githubusercontent.com/chenyong2github/TF2CharacterRendering/master/Screenshots/6j.jpg)
