-define(APP, nari_sim_client).

-record(sim_opts, {
    username,
    password,
    host,
    port,
    sub_topics,
    pub_topic
}).