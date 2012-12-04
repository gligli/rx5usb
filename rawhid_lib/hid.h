#define RHAPI __declspec(dllexport)

#ifdef OS_WINDOWS
#define RHCALL __stdcall
#else
#define RHCALL
#endif

#ifdef __cplusplus
extern "C"
{
#endif

RHAPI int RHCALL rawhid_open(int max, int vid, int pid, int usage_page, int usage);
RHAPI int RHCALL rawhid_recv(int num, void *buf, int len, int timeout);
RHAPI int RHCALL rawhid_send(int num, void *buf, int len, int timeout);
RHAPI void RHCALL rawhid_close(int num);

#ifdef __cplusplus
} // __cplusplus defined.
#endif