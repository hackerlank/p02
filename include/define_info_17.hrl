-include("define_info_0.hrl").

-define(NO_MORE_BOSS, 17000).    %%同种boss不能同时开启多个
-define(BOSS_INFO_NOT_FOUND, 17001).  %%boss数据没有找到
-define(INFO_BOSS_NOT_IN_TIME, 17002).  %%不在boss有效时间内
-define(INFO_BOSS_MAX_COUNT, 17003).  %%该boss挑战人数已达到上限
-define(OPEN_BOSS_FAIL, 17010).  %%boss开启失败
-define(INFO_OPEN_BOSS_FULL_TODAY, 17011).  %%该boss今天开启次数已用完
-define(INFO_OPEN_BOSS_FULL_CUR_HOUR, 17012). %%该boss当前小时开启次数已用完
-define(BOSS_IS_KILLED, 17013). %%该boss已经阵亡
-define(INFO_BOSS_OPEN_NOT_VALID_TIME, 17014). %%不在boss开启时间
-define(INFO_BOSS_OPEN_NOT_VALID, 17015). %%当前不能开启Boss
