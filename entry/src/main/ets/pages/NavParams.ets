// NavParams.ets — Navigation 跳转参数（ArkTS 要求显式类型，不能用对象字面量）

// ServiceWebPage 参数：标题 + H5 URL
export class WebPageParam {
  title: string = '';
  url: string = '';

  constructor(title: string, url: string) {
    this.title = title;
    this.url = url;
  }
}
