# OpenFOAM 验证模型

本 skill 将一次性的源码/工具链验收与日常回归分开。前者可以运行完整
`Allwmake`；后者应复用已经验收的安装。

## 隔离

每个作业创建唯一目录，包含新鲜源码归档、最小 ThirdParty 快照
（`sources/scotch` 和 `etc`）、独立 buildroot、日志和验证 case。不得从
其他工具链复制生成的 `build`、`platforms` 或 `lnInclude`。

## 昆山已确认的工具链事实

- OpenFOAM v2606 需要现代 GCC，系统 GCC 4.8.5 不适用。
- OpenMPI 5.0.11 可以通过 `OMPI_CC`、`OMPI_CXX`、`OMPI_FC` 切换到 GCC11。
- 现场旧 TBB 与 GCC11/GCC16 的 libstdc++ PSTL backend 不兼容；
  `-D_PSTL_PAR_BACKEND_SERIAL` 已通过 MPI/PSTL 探针和核心构建。
- GCC16 下 Scotch 6.1.0 的旧 C 源码需要 `-std=gnu17`，以处理现场出现的
  函数指针兼容性诊断。
- 旧 CMake 可能导致 KAHIP/ADIOS2 等可选组件失败，应与 OpenFOAM 核心结果
  分开判定。

以上是一个站点和版本的实证，不是对所有集群的兼容性承诺。

## 成功证据

记录：

- 源码 commit 和工具链；
- 作业目录、队列和资源请求；
- 调度器终态及平台退出状态；
- `allwmake_rc`；
- `foamInstallationTest` 返回码和输出；
- 可执行的 `icoFoam`；
- 真实错误标记扫描；
- `blockMesh`、`icoFoam`、重复安装测试和 `End` 标记。

公开证据中不要写入私有路径、凭证、节点名或原始工作负载数据。详细作业
记录保留在私有运行日志中。
