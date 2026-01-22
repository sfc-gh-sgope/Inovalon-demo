    SELECT 
    cu.timestamp,
    cu.pod_name as Runtime_Pod,
    cu.cpu_used as CPU_Used_Raw,
    lc.cores_available as Cores_Available,
    ROUND((cu.cpu_used / lc.cores_available) * 100, 2) as CPU_Usage_Percentage
FROM (
    SELECT 
        timestamp,
        resource_attributes:"k8s.pod.name" as pod_name,
        value as cpu_used
    FROM Identifier($TBL)
    WHERE true
        AND timestamp > dateadd(minutes, -30, sysdate())
        AND resource_attributes:"k8s.namespace.name"  = 'runtime-shaanmultidbswitch'
        AND resource_attributes:"k8s.container.name" like '%-server'
        AND record_type = 'METRIC'
        AND record:metric:name = 'container.cpu.usage'
) cu
ASOF JOIN (
    SELECT 
        timestamp,
        resource_attributes:"k8s.pod.name" as pod_name,
        value as cores_available
    FROM Identifier($TBL)
    WHERE true
        AND timestamp > dateadd(minutes, -30, sysdate())
        AND resource_attributes:"k8s.namespace.name" = 'runtime-shaanmultidbswitch'
        AND record_type = 'METRIC'
        AND record:metric:name = 'cores.available'
) lc
MATCH_CONDITION(cu.timestamp >= lc.timestamp)
ON cu.pod_name = lc.pod_name
WHERE lc.cores_available IS NOT NULL
ORDER BY cu.timestamp DESC;
