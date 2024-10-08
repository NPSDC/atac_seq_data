from os.path import join
import yaml
if not workflow.overwrite_configfiles:
    configfile: "config.yml"

# wf_path = config["wf_local"]
# wf_local = join(wf_path, "config.yaml")
# with open(wf_local, 'r') as f:
#     qos_type = yaml.safe_load(f)

# def get_qos(rule_name):
#     return qos_type[rule_name] if rule_name in qos_type else qos_type['default-resources']

# input_ref_file = config["ref_fasta_input"]

ind_output_path = join(pisc_output_path, "index")
k = config["k"]
pref_ind_k = f"{{org}}_k{k}"
mins = config["m"] #minimizers

ind_k_main_dir = join(ind_output_path, pref_ind_k)
ind_k_m_dir = join(ind_k_main_dir, "m{m}")
ind_k_m_pref = join(ind_k_m_dir, f"{pref_ind_k}_m{{m}}")
time_ind = join(ind_k_m_dir, f"time_k{k}_m{{m}}.out")

piscem_exec_path = config["piscem_path"]

rule all_piscem_ind:
    input:
        expand(f"{ind_k_m_pref}.sshash", m = mins, org = input_ref_org),
        expand(time_ind, m = mins, org = input_ref_org)

rule run_pisc_index:
    input:
        input_ref_file = lambda wildcards:input_ref_dict[wildcards.org]
    output:
        ind_sshash = f"{ind_k_m_pref}.sshash",
        ind_ectab = f"{ind_k_m_pref}.ectab",
        ind_ctab = f"{ind_k_m_pref}.ctab",
        ind_refinfo = f"{ind_k_m_pref}.refinfo",
        ind_json = f"{ind_k_m_pref}_cfish.json",
        time_ind = time_ind
    params:
        ind_pref = ind_k_m_pref,
        k = k,
        m = lambda wildcards:wildcards.m,
        piscem_exec_path = join(piscem_exec_path, "target", "release", "piscem"),
        threads = get_qos("run_pisc_index")["cpus_per_task"],
        tmpdir = join(config["tmp_dir"], "m{m}")
 
    shell:
        """
            export TMPDIR=/scratch0
            ulimit -n 2048
            /usr/bin/time -o {output.time_ind} {params.piscem_exec_path} build \
                -s {input.input_ref_file} \
                -k {params.k} \
                -m {params.m} \
                -t {params.threads} \
                -o {params.ind_pref} \
                -w {params.tmpdir} \
                --overwrite
        """