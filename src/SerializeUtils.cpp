
#include "SerializeUtils.h"


////////////////////////////////////////////////////////////////////////////////
//  SERIALIZE TO SHM  //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void SerializeToShm::Reserve(size_t size)
{
    int shm_id = shmget(IPC_PRIVATE, size, SHM_R|SHM_W);
    if(shm_id<0) throw new std::bad_alloc;

    m_buf = (byte_t *)shmat(shm_id,NULL,0);
    m_buf_size = size;
}

void SerializeToShm::ClearBuffer()
{
    if (m_buf) shmdt(m_buf);
    m_buf = NULL;
}


//    void * shm_create(key_t ipc_key, int shm_size, int perm, int fill = 0)
//    {
//        int shm_id;
//        void * shm_ptr;
//        shm_id = shmget(ipc_key, shm_size, IPC_CREAT|perm);
//        if (shm_id < 0) {
//            return NULL;
//        }
//        shm_ptr = shmat(shm_id, NULL, 0);
//        if (shm_ptr < 0) {
//            return NULL;
//        }
//        memset((void *)shm_ptr, fill, shm_size);
//        return shm_ptr;
//    }

//    void * shm_find(key_t ipc_key, int shm_size)
//    {
//        void * shm_ptr;
//        int shm_id;
//        shm_id = shmget(ipc_key, shm_size, 0);
//        if (shm_id < 0) {
//            return NULL;
//        }
//        shm_ptr = shmat(shm_id, NULL, 0);
//        if (shm_ptr < 0) {
//            return NULL;
//        }
//        return shm_ptr;
//    }

//    int shm_remove(key_t ipc_key, void * shm_ptr)
//    {
//        int shm_id;
//        if (shmdt(shm_ptr) < 0) {
//            return -1;
//        }
//        shm_id = shmget(ipc_key, 0, 0);
//        if (shm_id < 0) {
//            if (errno == EIDRM) return 0;
//            return -1;
//        }
//        if (shmctl(shm_id, IPC_RMID, NULL) < 0) {
//            if (errno == EIDRM) return 0;
//            return -1;
//        }
//        return 0;
//    }




