Vue

.vue用于将同属于一个组件的老三样封装在一起
Vue的核心功能是声明式渲染：通过js状态来描述html应该是什么样子的 当状态改变时 HTML会自动更新

lab式学习：

1.v-bind

```
<script setup>
import { ref } from 'vue'

const titleClass = ref('title')
</script>

<template>
  <h1 :class="titleClass">Make me red</h1>
</template>

<style>
.title {
  color: red;
}
</style>



//titleClass => title => .title
```

2.v-on

```
<script setup>
import { ref } from 'vue'

const count = ref(0)

function increment() {
  count.value++
}
</script>

<template>
  <button @click="increment">Count is: {{ count }}</button>
</template>



//increment => function increment => function的f1
```

3.v-model 表单绑定

```
<script setup>
import { ref } from 'vue'

const text = ref('')

</script>

<template>
  <input v-model="text" placeholder="Type here">
  <p>{{ text }}</p>
</template>
```

4.v-if

```
<script setup>
import { ref } from 'vue'

const awesome = ref(true)

function toggle() {
  awesome.value = !awesome.value
}
</script>

<template>
  <button @click="toggle">Toggle</button>
  <h1 v-if="awesome">Vue is awesome!</h1>
  <h1 v-else>Oh no 😢</h1>
</template>
```



## 一、基础

### 1.First Step

```
import { createApp } from 'Vue'

const app = createApp({})

//每个Vue应用都是通过 createApp 函数创建一个新的应用实例

我们传入 createApp 的对象实际上是一个组件，每个应用都需要一个“根组件”，其他组件将作为其子组件。

如果你使用的是单文件组件，我们可以直接从另一个文件中导入根组件。

import { createApp } from 'vue'
// 从一个单文件组件中导入根组件
import App from './App.vue'

const app = createApp(App)
```

【挂载容器】应用实例必须在调用了 `.mount()` 方法后才会渲染出来。该方法接收一个“容器”参数，可以是一个实际的 DOM 元素或是一个 CSS 选择器字符串：

![image-20251109023939625](C:\Users\Dragon\AppData\Roaming\Typora\typora-user-images\image-20251109023939625.png)

### 2.模版语法

1.文本插值：

```
<span>Message: {{msg}}</span>
这俩值以后一直绑定 msg更改时Message值也会同步改变
```

