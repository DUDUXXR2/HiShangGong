// NavParams.ets — Navigation 跳转参数（ArkTS 要求显式类型，不能用对象字面量）

// ServiceWebPage 参数：标题 + H5 URL
export class WebPageParam {
  title: string = '';
  url: string = '';
  immersive: boolean = false;

  constructor(title: string, url: string, immersive?: boolean) {
    this.title = title;
    this.url = url;
    if (immersive !== undefined) {
      this.immersive = immersive;
    }
  }
}

const JW_SERVICE_NAMES: string[] = [
  '缓考申请', '空闲教室', '学生成绩查询', '学生课表查询',
  '学生评教', '学生预警查询', '教师课表查询'
];

export function isJwServiceName(name: string): boolean {
  for (let i = 0; i < JW_SERVICE_NAMES.length; i++) {
    if (name === JW_SERVICE_NAMES[i]) {
      return true;
    }
  }
  return false;
}
