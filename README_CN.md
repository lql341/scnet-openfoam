# scnet-openfoam

[English](README.md) | 中文

当前版本：0.1.0

在 SCNet 计算节点上执行 OpenFOAM 构建和短数值 smoke 验证。本应用 skill
坚持远端优先：OpenFOAM 编译、安装测试、tutorial 和数值验证都应在目标计算
节点执行，不在 agent 本机编译。

第一版面向 OpenFOAM v2606、Slurm/OpenMPI，并整理了昆山 `kseshell` 验证中
实际确认的约束。脚本已参数化，不包含维护者私有远端路径或作业结果。

## 一句话让 agent 安装

将这句话发给 Codex：

> 使用 `$skill-installer` 从 GitHub 仓库 `lql341/scnet-openfoam` 的根目录（path `.`、ref `main`）安装 `scnet-openfoam`，不覆盖已有目录；在安装目录运行 `scripts/validate.sh` 并报告绝对安装路径；安装阶段不要编译 OpenFOAM，也不要提交集群作业。

## 范围

仓库提供：

- GCC11/GCC16 的 OpenFOAM v2606 独立构建作业；
- 编译器、MPI 和串行 PSTL 工具链探针；
- 短 `blockMesh` + `icoFoam` cavity smoke；
- 安装、幂等性和 relocation 检查；
- 成功门槛和已知失败模式记录。

仓库不打包 OpenFOAM，不安装集群 module，也不会在没有实时查询时声称
某个队列或编译器可用。

## 远端输入

提交作业时设置：

```text
OPENFOAM_SOURCE_ROOT       包含目标 OpenFOAM commit 的 Git 源码树
OPENFOAM_THIRDPARTY_ROOT   包含 sources/scotch 和 etc 的 ThirdParty 源码树
OPENFOAM_SRC_COMMIT        要归档的不可变 OpenFOAM commit
OPENFOAM_RUN_ROOT          用于创建唯一作业目录的可写根目录
```

作业调度、状态查询、等待和取消优先使用 `scnet-hpc` OpenAPI。SSH 只用于
上传脚本和有限日志诊断。GCC11 与 GCC16 不得共享 `buildroot`、`platforms`、
`lnInclude` 或可变 ThirdParty 构建目录。

## 工作流

```bash
bash scripts/openfoam_toolchain_probe.sh
bash scripts/openfoam_build_isolated.sbatch
bash scripts/openfoam_tutorial_smoke.sbatch
bash scripts/openfoam_postbuild.sbatch
```

这些脚本是 Slurm 作业体，应通过调度器在计算节点执行；不要在本机运行
OpenFOAM 构建。构建脚本接受 `FOAM_TOOLCHAIN=gcc11` 或 `gcc16`。

## 成功门槛

`Allwmake` 返回 0 不能单独作为成功依据。成功构建还必须同时满足：

1. `foamInstallationTest` 返回 0 且输出真实成功信息；
2. `icoFoam` 存在并可执行；
3. 没有真实编译器、fatal 或 CMake 错误标记；
4. 调度器确认作业完成且平台退出状态为 0；
5. 短 tutorial 中 `blockMesh`、`icoFoam` 和重复安装测试成功，日志到达 `End`。

完整 `Allwmake` 只作为一次性工具链/源码验收。日常回归应复用已验收安装，
只运行探针、安装测试和短 tutorial。

详见[英文验证说明](references/validation.md)和[中文验证说明](references/validation_CN.md)。

## 本地校验

```bash
bash scripts/validate.sh
```

这只检查仓库脚本和文档，不编译 OpenFOAM，也不访问集群。

MIT 许可证。
