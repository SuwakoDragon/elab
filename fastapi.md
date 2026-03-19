之前制作了一个静态的网页 现在试重构并丰富该项目
我们的GPT4o告诉我要学FastAPI 数据库操作 RESTful API 设计 前后端交互 前端框架 Vue 3 用户认证
以期达成

1. 第一阶段：功能完善
   - 添加动态内容支持（FastAPI + 数据库）。
   - 重构前端（Vue 3 + Vite）。

始まるよ！

# FastAPI

## 一、前置

### 1.Python类型简介

```
def get_full_name(first_name: str, last_name: str):
    full_name = first_name.title() + " " + last_name.title()
    return full_name


print(get_full_name("john", "doe"))
```

```
def process_items(items: list[str]):
    for item in items:
        print(item.)
//请注意，该变量item是列表中的一个元素items。

//Tuple
def process_items(items_t: tuple[int, int, str], items_s: set[bytes]):
    return items_t, items_s

//Dict
def process_items(prices: dict[str, float]):
    for item_name, item_price in prices.items():
        print(item_name)
        print(item_price)

//union
def process_item(item: int | str):
    print(item)

//None
from typing import Optional


def say_hi(name: Optional[str] = None):
    if name is not None:
        print(f"Hey {name}!")
    else:
        print("Hello World")
```

在Python中"type hints"以最大程度利用代码补全

### 2.并发与async/await

并发 排号
并行 就是并行
并发+并行 其实就是孙老师横向在做的工作

而现代Python提供了内置的异步代码实现 我们直接使用即可 FastAPI

```
burgers = await get_burgers(2)
//“await”告诉Python在赋值之前要等待右值完成运算

async def get_burgers(number: int):
    # Do some asynchronous stuff to create the burgers
    return burgers
//需要配合这种函数 即async def
```

### 3.环境变量

```
*💬 你可以创建一个名为 MY_NAME 的环境变量*
export MY_NAME="Wade Wilson"
*💬 然后你就可以把它和其他程序一起使用，比如*
echo“你好$MY_NAME”
你好，韦德·威尔逊
```

环境变量只能处理**文本字符串**

### 4.虚拟环境

环境变量对应的概念就是虚拟环境
venv是Python自带的虚拟环境库
如果你正在使用**Git**（你应该使用），请添加一个`.gitignore`文件，将你目录中的所有内容排除`.venv`在 Git 之外。

个人感觉这还是版本控制 

```
python -m venv .venv
//该命令会在名为 . 的目录中创建一个新的虚拟环境.venv。
```

激活虚拟环境后 虚拟环境将该环境下环境变量置顶 PATH将优先查找该环境下环境变量

## 二、基础

### 1.First Step

```
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
```

**FastAPI** 使用定义 API 的 **OpenAPI** 标准将你的所有 API 转换成「模式」。

- ```
  `@app.get("/")` 告诉 **FastAPI** 在它下方的函数负责处理如下访问请求：
  
  - 请求路径为 `/` 路径为第一个/之后的
  - 使用 `get` 操作 （上周的POST GET PUT DELETE那些）
  - @仍代表Python装饰器 可以理解为一个路径操作装饰器
  ```

```
async def root():
这是我们的「路径操作函数」：

路径：是 /。
操作：是 get。
函数：是位于「装饰器」下方的函数（位于 @app.get("/") 下方）。
每当 FastAPI 接收一个使用 GET 方法访问 URL「/」的请求时这个函数会被调用。

在这个例子中，它是一个 async 函数。
```

个人理解就是上周学的请求 基于OpenAPI协议进行了修改 URL+状态码 （GET www.baidu.com 这种感觉)

### 2.路径参数

FastAPI 支持使用 Python 字符串格式化语法声明**路径参数**（**变量**）

```
from fastapi import FastAPI

app = FastAPI()

@app.get("/items/{item_id}")
async def read_item(item_id):
    return {"item_id": item_id}
这段代码把路径参数 item_id 的值传递给路径函数的参数 item_id。

访问http://127.0.0.1:8000/items/foo
返回值为{"item_id":"foo"}
```

```
from fastapi import FastAPI

app = FastAPI()

@app.get("/items/{item_id}")
async def read_item(item_id: int):
    return {"item_id": item_id}
    
访问http://127.0.0.1:8000/items/foo
返回HTTP错误信息
```

C:\Users\Dragon\Desktop\demo\images\fastapi_1.png

说实话不懂 但是死记硬背吧

```
from enum import Enum
class ModelName(str, Enum):
    alexnet = "alexnet"
    resnet = "resnet"
    lenet = "lenet"
可以用这种方式

from enum import Enum

from fastapi import FastAPI


class ModelName(str, Enum):
    alexnet = "alexnet"
    resnet = "resnet"
    lenet = "lenet"


app = FastAPI()


@app.get("/models/{model_name}")
async def get_model(model_name: ModelName):
    if model_name is ModelName.alexnet:
        return {"model_name": model_name, "message": "Deep Learning FTW!"}

    if model_name.value == "lenet":
        return {"model_name": model_name, "message": "LeCNN all the images"}

    return {"model_name": model_name, "message": "Have some residuals"}
```

用枚举指定参数的方式 也可以返回参数
如果是包含路径的路径参数

```
/files/{file_path:path}
```

### 3.查询参数

声明的参数不是路径参数时，路径操作函数会把该参数自动解释为查询参数

```
from fastapi import FastAPI

app = FastAPI()

fake_items_db = [{"item_name": "Foo"}, {"item_name": "Bar"}, {"item_name": "Baz"}]


@app.get("/items/")
async def read_item(skip: int = 0, limit: int = 10)://这是带的默认值
    return fake_items_db[skip : skip + limit]
    
    
//查询字符串是键值对的集合，这些键值对位于 URL 的 ? 之后，以 & 分隔。
http://127.0.0.1:8000/items/?skip=0&limit=10
skip：值为 0
limit：值为 10
这些值都是 URL 的组成部分，因此，它们的类型本应是字符串。
但声明 Python 类型（上例中为 int）之后，这些值就会转换为声明的类型，并进行类型校验。
```



C:\Users\Dragon\Desktop\demo\images\fastapi_2.png

```
from fastapi import FastAPI

app = FastAPI()


@app.get("/items/{item_id}")
async def read_item(item_id: str, q: str | None = None, short: bool = False):
    item = {"item_id": item_id}
    if q:
        item.update({"q": q})
    if not short:
        item.update(
            {"description": "This is an amazing item that has a long description"}
        )
    return item
    
//bool



from fastapi import FastAPI

app = FastAPI()


@app.get("/users/{user_id}/items/{item_id}")
async def read_user_item(
    user_id: int, item_id: str, q: str | None = None, short: bool = False
):
    item = {"item_id": item_id, "owner_id": user_id}
    if q:
        item.update({"q": q})
    if not short:
        item.update(
            {"description": "This is an amazing item that has a long description"}
        )
    return item

//多个也可以
```



### 4.请求体

FastAPI 使用**请求体**从客户端（例如浏览器）向 API 发送数据。
**请求体**是客户端发送给 API 的数据。**响应体**是 API 发送给客户端的数据。
API 基本上肯定要发送**响应体**，但是客户端不一定发送**请求体**。

```
//在路径操作函数内部直接访问模型对象的属性
from fastapi import FastAPI
from pydantic import BaseModel


class Item(BaseModel):
    name: str
    description: str | None = None
    price: float
    tax: float | None = None


app = FastAPI()

@app.post("/items/")
async def create_item(item: Item):
    item_dict = item.dict()
    if item.tax is not None:
        price_with_tax = item.price + item.tax
        item_dict.update({"price_with_tax": price_with_tax})
    return item_dict
```

### 5.参数查询的校验与限制

```
from typing import Union

from fastapi import FastAPI, Query

app = FastAPI()


@app.get("/items/")
async def read_items(q: Union[str, None] = Query(default=None, max_length=50)):
    results = {"items": [{"item_id": "Foo"}, {"item_id": "Bar"}]}
    if q:
        results.update({"q": q})
    return results
```

```
//还可以使用正则表达式
from typing import Union

from fastapi import FastAPI, Query

app = FastAPI()


@app.get("/items/")
async def read_items(
    q: Union[str, None] = Query(
        default=None, min_length=3, max_length=50, pattern="^fixedquery$"
    ),
):
    results = {"items": [{"item_id": "Foo"}, {"item_id": "Bar"}]}
    if q:
        results.update({"q": q})
    return results
```

### 6.……

在理解OpenAPI协议对路径、参数、请求体的重定义之后 一直在介绍各种语法

### 7.









































